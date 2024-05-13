use super::Page;
use super::SharedState;
use axum::extract::Path;
use axum::{
    extract::State,
    response::{Html, IntoResponse, Redirect, Response},
    Form,
};
use chrono::NaiveDate;
use futures::TryStreamExt;
use mongodb::bson::doc;
use mongodb::bson::oid::ObjectId;
use mongodb::Collection;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use std::sync::Arc;
use tera::Context;

#[derive(Deserialize, Serialize)]
pub struct PostForm {
    content: String,
    description: String,
    preview: String,
    published_at: Option<String>,
    revised_at: Option<String>,
    slug: String,
    title: String,
}

pub async fn index(State(state): State<Arc<SharedState>>) -> Response {
    let collection: Collection<super::Page> = state.mongo.database("blog").collection("pages");

    let mut cursor = collection.find(doc! {}, None).await.unwrap();

    let mut pages: Vec<Page> = Vec::new();

    while let Some(mut page) = cursor.try_next().await.unwrap() {
        page.id = Some(page._id.to_hex());
        pages.push(page)
    }

    let mut context = tera::Context::new();
    context.insert("pages", &pages);
    println!("{:?}", pages);

    let rendered = state.tera.render("admin/index.html", &context).unwrap();

    return Html(rendered).into_response();
}

pub async fn new(State(state): State<Arc<SharedState>>) -> Response {
    let rendered = state
        .tera
        .render("admin/new.html", &Context::new())
        .unwrap();

    Html(rendered).into_response()
}

pub async fn edit(State(state): State<Arc<SharedState>>, Path(id): Path<String>) -> Response {
    let tera = &state.tera;
    let database: &mongodb::Database = &state.mongo.database("blog");
    let mut context = tera::Context::new();
    let oid = ObjectId::from_str(&id).unwrap();

    let collection: Collection<Page> = database.collection("pages");
    let mut page = collection
        .find_one(doc! {"_id": oid}, None)
        .await
        .unwrap()
        .unwrap();

    page.id = Some(page._id.to_string());

    context.insert("page", &page);
    let rendered = tera.render("admin/edit.html", &context).unwrap();

    Html(rendered).into_response()
}

pub async fn create(
    State(shared_state): State<Arc<SharedState>>,
    Form(form): Form<PostForm>,
) -> Response {
    let collection = shared_state.mongo.database("blog").collection("pages");

    let new_page = Page {
        _id: mongodb::bson::oid::ObjectId::new(),
        content: form.content.clone(),
        created_at: mongodb::bson::DateTime::now(),
        description: form.description,
        id: None,
        markdown: form.content,
        preview: form.preview,
        published_at: None,
        revised_at: None,
        slug: form.slug,
        title: form.title,
        updated_at: mongodb::bson::DateTime::now(),
    };

    let _result = collection.insert_one(new_page, None).await;

    return Redirect::to("/admin/pages").into_response();
}

pub async fn update(
    State(state): State<Arc<SharedState>>,
    Path(id): Path<String>,
    Form(form): Form<PostForm>,
) -> Response {
    let database: &mongodb::Database = &state.mongo.database("blog");
    let collection: Collection<Page> = database.collection("pages");
    let oid = ObjectId::from_str(&id).unwrap();

    let mut page = collection
        .find_one(doc! {"_id": oid}, None)
        .await
        .unwrap()
        .unwrap();

    if let Some(date) = form.published_at {
        match NaiveDate::parse_from_str(&date, "%Y-%m-%d") {
            Ok(date) => page.published_at = Some(date.and_hms_opt(0, 0, 0).unwrap().and_utc()),
            Err(err) => {
                println!("{}", err);
            }
        }
    }

    if let Some(date) = form.revised_at {
        match NaiveDate::parse_from_str(&date, "%Y-%m-%d") {
            Ok(date) => page.revised_at = Some(date.and_hms_opt(0, 0, 0).unwrap().and_utc()),
            Err(_) => {}
        }
    }

    page.content = form.content;
    page.description = form.description;
    page.title = form.title;
    page.preview = form.preview;

    let _result = collection.replace_one(doc! {"_id": oid}, page, None).await;

    return Redirect::to("/admin/pages").into_response();
}
