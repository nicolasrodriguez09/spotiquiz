# Spotiquiz

Quiz personal hecho con Flutter usando los datos reales del usuario en Spotify.

## Que hace este MVP

- Login con Spotify usando Authorization Code + PKCE.
- Lee perfil, top artists, top tracks y recently played.
- Genera un quiz de 5 preguntas con distractores razonables.
- Muestra resultado final, nivel y resumen compartible.
- Permite escuchar previews cuando Spotify devuelve `preview_url`.

## Configuracion de Spotify

Esta entrega ya incluye un Client ID por defecto para que puedas ejecutar la app
sin argumentos extra.

En Spotify for Developers, la app debe tener este Redirect URI:

```text
spotiquiz://callback
```

Y estos scopes:

```text
user-read-private user-top-read user-read-recently-played
```

Nota: si la app de Spotify esta en Development Mode, Spotify solo permite usarla
a los usuarios agregados en el dashboard de la app. Para que cualquier cuenta de
Spotify pueda entrar sin estar en esa lista, la app debe estar en Extended Quota
Mode.

## Ejecutar

```bash
flutter pub get
flutter run
```

Opcionalmente puedes usar otro Client ID sin cambiar el codigo:

```bash
flutter run --dart-define=SPOTIFY_CLIENT_ID=tu_client_id
```

Si quieres cambiar el redirect URI por otro esquema, tambien debes actualizar la configuracion nativa en:

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

## Estructura base

- `lib/services`: autenticacion Spotify, consumo de API y generacion del quiz
- `lib/controllers`: estado principal de la app
- `lib/presentation`: flujo UI del MVP
- `lib/models`: modelos Spotify y quiz

## Notas

- Este proyecto esta armado para un MVP movil.
- En Windows, algunos plugins pueden requerir tener habilitado `Developer Mode` para que Flutter cree symlinks correctamente.
