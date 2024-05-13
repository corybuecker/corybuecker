use axum::extract::Query;
use axum::response::Html;
use openidconnect::core::{CoreAuthenticationFlow, CoreClient, CoreProviderMetadata};
use openidconnect::reqwest::async_http_client;
use openidconnect::{
    AuthorizationCode, ClientId, ClientSecret, CsrfToken, IssuerUrl, Nonce, RedirectUrl, Scope,
    TokenResponse,
};
use serde::Deserialize;
use std::env;
use tower_cookies::{Cookie, Cookies, Key};

pub async fn login(cookies: Cookies) -> Html<String> {
    let discovery_url = IssuerUrl::new("https://accounts.google.com".to_string())
        .ok()
        .unwrap();
    let provider_metadata = CoreProviderMetadata::discover_async(discovery_url, async_http_client)
        .await
        .unwrap();

    let client_id = env::var("GOOGLE_CLIENT_ID").unwrap();
    let client_secret = env::var("GOOGLE_CLIENT_SECRET").unwrap();

    let client = CoreClient::from_provider_metadata(
        provider_metadata,
        ClientId::new(client_id),
        Some(ClientSecret::new(client_secret)),
    )
    .set_redirect_uri(
        RedirectUrl::new("http://localhost:8000/admin/login/callback".to_string()).unwrap(),
    );

    let (auth_url, _, nonce) = client
        .authorize_url(
            CoreAuthenticationFlow::AuthorizationCode,
            CsrfToken::new_random,
            Nonce::new_random,
        )
        .add_scope(Scope::new("email".to_string()))
        .add_scope(Scope::new("openid".to_string()))
        .url();

    let cookie = Cookie::build(("nonce", nonce.secret().clone()))
        .expires(None)
        .http_only(true)
        .path("/admin")
        .build();

    let key_base = env::var("SECRET_KEY").unwrap();
    let key = Key::from(key_base.as_bytes());
    let signed_cookies = cookies.signed(&key);

    signed_cookies.add(cookie);

    return Html(auth_url.to_string());
}

#[derive(Deserialize, Debug)]
pub struct GoogleCallback {
    code: String,
}
pub async fn callback(
    Query(callback): Query<GoogleCallback>,
    cookies: Cookies,
) -> Html<&'static str> {
    let discovery_url = IssuerUrl::new("https://accounts.google.com".to_string())
        .ok()
        .unwrap();
    let provider_metadata = CoreProviderMetadata::discover_async(discovery_url, async_http_client)
        .await
        .unwrap();

    let client_id = env::var("GOOGLE_CLIENT_ID").unwrap();
    let client_secret = env::var("GOOGLE_CLIENT_SECRET").unwrap();

    let client = CoreClient::from_provider_metadata(
        provider_metadata,
        ClientId::new(client_id),
        Some(ClientSecret::new(client_secret)),
    )
    .set_redirect_uri(
        RedirectUrl::new("http://localhost:8000/admin/login/callback".to_string()).unwrap(),
    );

    let key_base = env::var("SECRET_KEY").unwrap();
    let key = Key::from(key_base.as_bytes());
    let signed_cookies = cookies.signed(&key);

    let nonce_cookie = signed_cookies.get("nonce").unwrap().value().to_string();
    let nonce = Nonce::new(nonce_cookie);

    let token_response = client
        .exchange_code(AuthorizationCode::new(callback.code.to_string()))
        .request_async(async_http_client)
        .await
        .unwrap();

    // Extract the ID token claims after verifying its authenticity and nonce.
    let id_token = token_response.id_token().unwrap();

    let claims = id_token
        .claims(&client.id_token_verifier(), &nonce)
        .unwrap();

    // The authenticated user's identity is now available. See the IdTokenClaims struct for a
    // complete listing of the available claims.
    println!(
        "User {} with e-mail address {} has authenticated successfully",
        claims.subject().as_str(),
        claims
            .email()
            .map(|email| email.as_str())
            .unwrap_or("<not provided>"),
    );

    let cookie = Cookie::build(("email", claims.email().unwrap().to_string()))
        .expires(None)
        .http_only(true)
        .path("/admin")
        .build();

    signed_cookies.add(cookie);
    let nonce = Cookie::build(("nonce", ""))
        .expires(None)
        .http_only(true)
        .path("/admin")
        .build();
    signed_cookies.remove(nonce);

    return Html("OK");
}
