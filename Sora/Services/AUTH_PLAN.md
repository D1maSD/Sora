# Sora — план авторизации

## Схема

1. `Apphud.userId()` → apphud_id
2. `POST /api/users` с `{ "apphud_id": "..." }` → получаем `user.id`
3. `POST /api/users/authorize` с `{ "user_id": "uuid" }` → получаем `access_token`
4. Сохраняем `user_id` и `access_token` в Keychain
5. Все запросы: `Authorization: Bearer <access_token>`

## Шаги (реализовано)

- [x] **Шаг 1.** Apphud: инициализация в `SoraApp.init()`, API key из инструкции
- [x] **Шаг 2.** `KeychainStorage`: saveUserId, getUserId, saveToken, getToken, clear
- [x] **Шаг 3.** `APIClient`: base URL, Content-Type, автоматический Bearer из Keychain, POST/GET, логирование 401/422
- [x] **Шаг 4.** `AuthService`: bootstrapUser(), register(), authorize(userId:), getToken()
- [x] **Шаг 5.** Splash: вызов `AuthService.shared.bootstrapUser()` до перехода на Onboarding/ContentView (параллельно с показом сплэша 2 сек)

## Логика bootstrapUser()

- Если есть `access_token` в Keychain → выходим (уже авторизован)
- Иначе если есть `user_id` → вызываем `authorize(user_id)`
- Иначе → вызываем `register()` (apphud_id → POST /api/users → сохраняем user_id → authorize)

## Файлы

- `KeychainStorage.swift` — хранение в Keychain
- `APIClient.swift` — HTTP-клиент с Bearer
- `AuthModels.swift` — DTO запросов/ответов
- `AuthService.swift` — оркестрация авторизации
- `SoraApp.swift` — init Apphud, вызов bootstrap на Splash

## Дальше

- Запросы генерации (POST /api/generations и т.д.) использовать через `APIClient.shared` с `useAuth: true` (по умолчанию для GET, для POST передать при вызове), тогда токен подставится автоматически.
