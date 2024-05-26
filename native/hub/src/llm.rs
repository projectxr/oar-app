use crate::messages;
use crate::tokio;
use anyhow::Result;
use llm::context::params::LlamaContextParams;
//use llm::ggml_time_us;
use build_target::Os;
use llm::llama_backend::LlamaBackend;
use llm::llama_batch::LlamaBatch;
use llm::model::params::LlamaModelParams;
use llm::model::LlamaModel;
use llm::model::{AddBos, Special};
use llm::token::data_array::LlamaTokenDataArray;
use llm::token::LlamaToken;
use std::io::Write;
use std::num::NonZeroU32;
use std::ops::Index;
use std::path::PathBuf;

#[derive(clap::Subcommand, Debug, Clone)]

enum Model {
    Local { path: PathBuf },
}

impl Model {
    /// Convert the model to a path - may download from huggingface
    fn get_or_load(self) -> Result<PathBuf> {
        match self {
            Model::Local { path } => Ok(path),
        }
    }
}

pub async fn parse() {
    let n_len: i32 = 8192;
    let model: Model = Model::Local {
        path: PathBuf::from(
            "/Users/prashantchoudhary/Library/Containers/com.example.app/Data/llama.gguf",
            // "/storage/emulated/0/Download/llama.gguf",
        ),
    };
    let ctx_size: Option<NonZeroU32> = NonZeroU32::new(8192);
    // init LLM
    let backend = LlamaBackend::init().expect("Failed to Initiate Backend");
    let model_params = {
        #[cfg(feature = "cublas")]
        if !disable_gpu {
            LlamaModelParams::default().with_n_gpu_layers(1000)
        } else {
            LlamaModelParams::default()
        }
        #[cfg(not(feature = "cublas"))]
        LlamaModelParams::default()
    };
    let model_path = model.get_or_load().expect("failed to get model from args");
    let model = LlamaModel::load_from_file(&backend, model_path, &model_params)
        .expect("Unable to load models");
    println!("Loaded!");
    messages::llm::LlmReady {
        ready: true,
        data: String::from("Loaded!"),
    }
    .send_signal_to_dart();
    let mut message_id: u32 = 0;
    let mut receiver = messages::llm::LlmRequest::get_dart_signal_receiver();
    tokio::spawn(async move {
        let mut sampling_token_list: Vec<LlamaToken> = vec![];
        while let Some(app_request) = receiver.recv().await {
            let prompt: String = app_request.message.prompt;
            let prompt: String = [
                "<|start_header_id|>user<|end_header_id|>",
                &prompt,
                "<|eot_id|><|start_header_id|>assistant<|end_header_id|>",
            ]
            .join("\n\n");

            let ctx_params = LlamaContextParams::default()
                .with_n_ctx(ctx_size)
                .with_n_batch(8192)
                .with_n_ubatch(128)
                .with_seed(1234)
                .with_n_threads(4);

            let mut ctx = model
                .new_context(&backend, ctx_params)
                .expect("unable to create the llama_context");

            let tokens_list = model
                .str_to_token(&prompt, AddBos::Always)
                .expect(format!("failed to tokenize {prompt}").as_str());

            //TODO: Research context extension in DEPTH!
            eprintln!("{} {}", sampling_token_list.len(), tokens_list.len());
            if sampling_token_list.len() + tokens_list.len()
                >= usize::try_from(n_len).expect("Length not available")
            {
                let save_size: i32 = n_len / 4;
                eprintln!("{} {}", save_size, n_len);
                sampling_token_list = sampling_token_list
                    .split_at(usize::try_from(save_size).expect(""))
                    .0
                    .to_vec();
                sampling_token_list.append(
                    &mut sampling_token_list
                        .split_at(usize::try_from(3 * save_size).expect(""))
                        .1
                        .to_vec(),
                );
            }
            sampling_token_list.append(&mut tokens_list.clone());

            let n_cxt = ctx.n_ctx() as i32;
            let n_kv_req =
                sampling_token_list.len() as i32 + (n_len - sampling_token_list.len() as i32);

            eprintln!("n_len = {n_len}, n_ctx = {n_cxt}, k_kv_req = {n_kv_req}");

            if n_kv_req > n_cxt {
                break;
            }

            // for token in &sampling_token_list {
            //     eprint!(
            //         "{}",
            //         model
            //             .token_to_str(*token, Special::Tokenize)
            //             .expect("Error in converting from token to str")
            //     );
            // }

            std::io::stderr().flush().expect("Flush error");
            let mut batch = LlamaBatch::new(8192, 1);

            let last_index: i32 = (sampling_token_list.len() - 1) as i32;
            for (i, token) in (0_i32..).zip(&sampling_token_list) {
                let is_last = i == last_index;
                batch
                    .add(*token, i, &[0], is_last)
                    .expect("Error in adding to batch");
            }

            ctx.decode(&mut batch).expect("llama_decode() failed");

            let mut n_cur = batch.n_tokens();
            // let mut n_decode = 0;

            // let t_main_start = ggml_time_us();

            let mut decoder = encoding_rs::UTF_8.new_decoder();
            while n_cur <= n_len {
                {
                    let candidates = ctx.candidates_ith(batch.n_tokens() - 1);

                    let mut candidates_p = LlamaTokenDataArray::from_iter(candidates, false);

                    candidates_p.sample_repetition_penalty(
                        None,
                        &sampling_token_list,
                        64,
                        1.1,
                        0.0,
                        0.0,
                    );

                    ctx.sample_top_k(&mut candidates_p, 40, 1);

                    ctx.sample_tail_free(&mut candidates_p, 1.0, 1);

                    ctx.sample_typical(&mut candidates_p, 1.0, 1);

                    ctx.sample_top_p(&mut candidates_p, 0.950, 1);

                    ctx.sample_min_p(&mut candidates_p, 0.05, 1);

                    ctx.sample_temp(&mut candidates_p, 0.1);

                    //ctx.sample_token_softmax(&mut candidates_p);
                    //let new_token_id = ctx.llama_sample_token_mirostat_v2(candidates_p);
                    let new_token_id = candidates_p.data[0].id();

                    sampling_token_list.push(new_token_id);
                    if new_token_id == model.token_eos() || new_token_id == model.token_eot() {
                        eprintln!();
                        break;
                    }

                    let output_bytes = model
                        .token_to_bytes(new_token_id, Special::Tokenize)
                        .expect("Failed to convert token to bytes");
                    // use `Decoder.decode_to_string()` to avoid the intermediate buffer
                    let mut output_string = String::with_capacity(32);
                    let _decode_result =
                        decoder.decode_to_string(&output_bytes, &mut output_string, false);
                    messages::llm::LlmResult {
                        response: output_string,
                        message_id,
                    }
                    .send_signal_to_dart();
                    batch.clear();
                    batch
                        .add(new_token_id, n_cur, &[0], true)
                        .expect("Failed to add to batch");
                }

                n_cur += 1;

                ctx.decode(&mut batch).expect("failed to eval");

                //n_decode += 1;
            }
            message_id = message_id + 1;
        }
    });

    // eprintln!("\n");

    // let t_main_end = ggml_time_us();

    // let duration = Duration::from_micros((t_main_end - t_main_start) as u64);

    // eprintln!(
    //     "decoded {} tokens in {:.2} s, speed {:.2} t/s\n",
    //     n_decode,
    //     duration.as_secs_f32(),
    //     n_decode as f32 / duration.as_secs_f32()
    // );

    // println!("{}", ctx.timings());
}
