use std::path::PathBuf;

use pdf::{
    build::*,
    content::{Cmyk, Color, Matrix, Op},
    error::PdfError,
    file::FileOptions,
    font::{Font, FontData, TFont},
    object::*,
    primitive::{Name, PdfString},
};

use clap::Parser;
