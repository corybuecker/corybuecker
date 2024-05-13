use std::{env, sync::Arc};
mod admin;
use axum::{
    extract::{Path, State},
    response::{Html, IntoResponse, Response},
    routing::get,
    Router,
};
use futures::TryStreamExt;
use mongodb::{bson::doc, options::FindOptions, Client, Collection};
use serde::{Deserialize, Serialize};
use serde_with::serde_as;
use tera::Tera;
use tower_http::services::ServeDir;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

pub struct SharedState {
    tera: Tera,
    mongo: Client,
}

#[serde_as]
#[derive(Serialize, Deserialize, Debug)]
struct Page {
    _id: mongodb::bson::oid::ObjectId,
    content: String,
    created_at: mongodb::bson::DateTime,
    description: String,
    id: Option<String>,
    markdown: String,
    preview: String,

    #[serde_as(as = "Option<bson::DateTime>")]
    published_at: Option<chrono::DateTime<chrono::Utc>>,

    #[serde_as(as = "Option<bson::DateTime>")]
    revised_at: Option<chrono::DateTime<chrono::Utc>>,
    slug: String,
    title: String,
    updated_at: mongodb::bson::DateTime,
}

async fn home(State(shared_state): State<Arc<SharedState>>) -> Response {
    let tera = &shared_state.tera;
    let mongo = shared_state
        .mongo
        .database("blog")
        .collection::<Page>("pages");

    let mut context = tera::Context::new();
    let find_options = FindOptions::builder()
        .sort(doc! {"published_at": -1})
        .build();

    let mut cur = mongo
        .find(
            doc! {"published_at": doc!{"$lte": mongodb::bson::DateTime::now()}},
            find_options,
        )
        .await
        .unwrap();

    let mut pages: Vec<Page> = Vec::new();

    while let Some(page) = cur.try_next().await.unwrap() {
        pages.push(page)
    }
    println!("{:?}", pages);

    let homepage = pages.pop();

    context.insert("pages", &pages);
    context.insert("homepage", &homepage);

    let rendered = tera.render("home.html", &context).unwrap();

    Html(rendered).into_response()
}

async fn page(Path(slug): Path<String>, State(shared_state): State<Arc<SharedState>>) -> Response {
    let tera = &shared_state.tera;
    let database = &shared_state.mongo.database("blog");
    let mut context = tera::Context::new();

    let collection: Collection<Page> = database.collection("pages");
    let page = collection
        .find_one(doc! {"slug": slug}, None)
        .await
        .unwrap()
        .unwrap();

    context.insert("page", &page);
    let rendered = tera.render("page.html", &context).unwrap();

    Html(rendered).into_response()
}

#[tokio::main]
async fn main() {
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "example_tokio_postgres=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    let mongo = Client::with_uri_str(env::var("DATABASE_URL").unwrap())
        .await
        .unwrap();
    let tera = Tera::new("templates/**/*.html").unwrap();

    let shared_state = Arc::new(SharedState { tera, mongo });

    // build our application with some routes
    let app = Router::new()
        .route("/", get(home))
        .route("/post/:slug", get(page))
        .nest_service("/assets", ServeDir::new("static"))
        .nest("/admin", admin::admin_routes(shared_state.clone()))
        .layer(tower_http::trace::TraceLayer::new_for_http())
        .with_state(shared_state.clone());

    // run it
    let listener = tokio::net::TcpListener::bind("127.0.0.1:8000")
        .await
        .unwrap();

    axum::serve(listener, app).await.unwrap();
}
