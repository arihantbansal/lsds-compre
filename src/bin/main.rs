use std::{sync::Arc, thread, time::Duration};

use clap::Parser;
use p2p_messages::start_example_raft_node;
use tracing_subscriber::EnvFilter;

#[derive(Parser, Clone, Debug)]
#[clap(author, version, about, long_about = None)]
pub struct Opt {
    #[clap(long)]
    pub id: u64,

    #[clap(long)]
    pub http_addr: String,

    #[clap(long)]
    pub initialized_at: u128,

    #[clap(long)]
    pub timeout: u64,
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let mut flag: Arc<bool> = Arc::new(false);

    // Setup the logger
    tracing_subscriber::fmt()
        .with_target(true)
        .with_thread_ids(true)
        .with_level(true)
        .with_ansi(false)
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    // Parse the parameters passed by arguments.
    let options = Opt::parse();

    let timeout = options.timeout.clone();

    let mut cloned_flag = flag.clone();

    let flag_updater = thread::spawn(move || {
        thread::sleep(Duration::from_millis(timeout * 1000));
        cloned_flag = Arc::new(false);
    });

    start_example_raft_node(
        options.id,
        options.http_addr,
        options.initialized_at,
        options.timeout,
        flag,
    )
    .await
}
