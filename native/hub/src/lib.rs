use tokio_with_wasm::tokio;

mod llm;
mod messages;
mod storage;

rinf::write_interface!();

async fn main() {
    tokio::spawn(llm::parse());
}
