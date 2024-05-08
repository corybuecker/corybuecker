use openidconnect::core::{CoreAuthenticationFlow, CoreClient, CoreProviderMetadata};
use openidconnect::reqwest::async_http_client;
use openidconnect::{
    AuthorizationCode, ClientId, ClientSecret, CsrfToken, IssuerUrl, Nonce, RedirectUrl, Scope,
    TokenResponse,
};
use rocket::http::CookieJar;
use rocket_dyn_templates::{context, Template};
use std::env;

#[get("/login")]
pub async fn login(cookies: &CookieJar<'_>) -> Template {
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

    cookies.add_private(("nonce", nonce.secret().clone()));

    return Template::render("admin/login", context! {auth_url: auth_url.to_string()});
}

#[get("/login/callback?<code>")]
pub async fn callback(cookies: &CookieJar<'_>, code: &str) {
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

    let nonce = Nonce::new(cookies.get_private("nonce").unwrap().value().to_string());

    let token_response = client
        .exchange_code(AuthorizationCode::new(code.to_string()))
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

    cookies.remove_private("nonce");

    cookies.add_private(("email", claims.email().unwrap().to_string()))
}
