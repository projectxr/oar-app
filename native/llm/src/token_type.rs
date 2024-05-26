//! Utilities for working with `llama_token_type` values.

/// A rust flavored equivalent of `llama_token_type`.
#[repr(u32)]
#[derive(Eq, PartialEq, Debug, Clone, Copy)]
#[allow(clippy::module_name_repetitions)]
pub enum LlamaTokenType {
    /// An undefined token type.
    Undefined = llm_cpp::LLAMA_TOKEN_TYPE_UNDEFINED as _,
    /// A normal token type.
    Normal = llm_cpp::LLAMA_TOKEN_TYPE_NORMAL as _,
    /// An unknown token type.
    Unknown = llm_cpp::LLAMA_TOKEN_TYPE_UNKNOWN as _,
    /// A control token type.
    Control = llm_cpp::LLAMA_TOKEN_TYPE_CONTROL as _,
    /// A user defined token type.
    UserDefined = llm_cpp::LLAMA_TOKEN_TYPE_USER_DEFINED as _,
    /// An unused token type.
    Unused = llm_cpp::LLAMA_TOKEN_TYPE_UNUSED as _,
    /// A byte token type.
    Byte = llm_cpp::LLAMA_TOKEN_TYPE_BYTE as _,
}

/// A safe wrapper for converting potentially deceptive `llama_token_type` values into
/// `LlamaVocabType`.
///
/// The error branch returns the original value.
///
/// ```
/// # use std::convert::TryFrom;
/// # use std::ffi::c_int;
/// # use std::num::TryFromIntError;
/// # use std::result::Result;
/// # use llm::token_type::{LlamaTokenTypeFromIntError, LlamaTokenType};
/// # fn main() -> Result<(), LlamaTokenTypeFromIntError> {
/// let llama_token_type = LlamaTokenType::try_from(0 as llm_cpp::llama_token_type)?;
/// assert_eq!(llama_token_type, LlamaTokenType::Undefined);
///
/// let bad_llama_token_type = LlamaTokenType::try_from(100 as llm_cpp::llama_token_type);
/// assert_eq!(Err(LlamaTokenTypeFromIntError::UnknownValue(100)), bad_llama_token_type);
/// # Ok(())
/// # }
impl TryFrom<llm_cpp::llama_token_type> for LlamaTokenType {
    type Error = LlamaTokenTypeFromIntError;

    fn try_from(value: llm_cpp::llama_vocab_type) -> Result<Self, Self::Error> {
        match value {
            llm_cpp::LLAMA_TOKEN_TYPE_UNDEFINED => Ok(LlamaTokenType::Undefined),
            llm_cpp::LLAMA_TOKEN_TYPE_NORMAL => Ok(LlamaTokenType::Normal),
            llm_cpp::LLAMA_TOKEN_TYPE_UNKNOWN => Ok(LlamaTokenType::Unknown),
            llm_cpp::LLAMA_TOKEN_TYPE_CONTROL => Ok(LlamaTokenType::Control),
            llm_cpp::LLAMA_TOKEN_TYPE_USER_DEFINED => Ok(LlamaTokenType::UserDefined),
            llm_cpp::LLAMA_TOKEN_TYPE_UNUSED => Ok(LlamaTokenType::Unused),
            llm_cpp::LLAMA_TOKEN_TYPE_BYTE => Ok(LlamaTokenType::Byte),
            _ => Err(LlamaTokenTypeFromIntError::UnknownValue(value as _)),
        }
    }
}

/// An error type for `LlamaTokenType::try_from`.
#[derive(thiserror::Error, Debug, Eq, PartialEq)]
pub enum LlamaTokenTypeFromIntError {
    /// The value is not a valid `llama_token_type`.
    #[error("Unknown Value {0}")]
    UnknownValue(std::ffi::c_uint),
}
