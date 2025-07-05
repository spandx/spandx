pub mod cli;
pub mod core;
pub mod parsers;
pub mod formatters;
pub mod spdx;
pub mod cache;
pub mod gateway;
pub mod git;
pub mod error;

pub use core::*;
pub use error::{SpandxError, SpandxResult};

use std::sync::OnceLock;
use tracing::Level;

static AIRGAP_MODE: OnceLock<bool> = OnceLock::new();

pub fn set_airgap_mode(airgap: bool) {
    let _ = AIRGAP_MODE.set(airgap);
}

pub fn is_airgap_mode() -> bool {
    AIRGAP_MODE.get().copied().unwrap_or(false)
}

pub fn init_tracing() {
    tracing_subscriber::fmt()
        .with_max_level(Level::INFO)
        .with_target(false)
        .init();
}