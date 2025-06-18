use axum::Router;
use tower_http::services::ServeDir;

#[tokio::main(flavor = "current_thread")]
async fn main() {
    let listener = tokio::net::TcpListener::bind("0.0.0.0:8080").await.unwrap();

    let app = Router::new().fallback_service(ServeDir::new("static"));
    axum::serve(listener, app).await.unwrap();
}
