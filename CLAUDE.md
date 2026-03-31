# CLAUDE.md — Motivation PRO

## Descripción del Proyecto

**Motivation PRO** es una app móvil Flutter de motivación personal, orientada principalmente a Android (iOS planeado para v2.0). Combina frases motivacionales locales y via APIs externas con IA generativa (Gemini), gamificación, notificaciones programadas y widget de pantalla de inicio.

**Tagline:** "Tu inspiración diaria"
**Versión actual:** 1.0.0 (Alpha)
**Estado:** Desarrollo activo — sistema de notificaciones en progreso

---

## Roadmap de Features

### Implementadas ✅
- Base de datos SQLite con versionado y migraciones
- Perfiles de usuario con personalización (tono, valores, retos)
- Sistema de frases: local + 3 APIs externas (ZenQuotes, Quotable, Type.fit)
- Favoritos / bookmarks
- Estadísticas, streaks y sistema de XP/niveles
- Badges/logros (gamificación)
- Notificaciones locales + programadas via AlarmManager
- Sistema de temas con persistencia
- Widget de pantalla de inicio (Android)
- Generación de frases con IA (Gemini API, fallback local)
- Soporte bilingüe español/inglés con traducción automática
- Detección de conectividad con degradación elegante
- Compartir frases (share_plus)
- UI de ajustes (tema, notificaciones, API, about)

### En desarrollo 🔄
- NotificationScheduler (AlarmManager integration) — archivos nuevos sin commitear
- Mejoras en comunicación del widget
- Confiabilidad de conexión

### Pendientes / Planificadas ❌
- Diario de reflexión personal
- Audio y Text-to-Speech
- Generador de imágenes motivacionales
- Análisis y estadísticas avanzadas
- Sincronización con backend / nube
- Soporte iOS
- Deep links
- Backup/restore

---

## Arquitectura

```
lib/
├── main.dart                        # Entry point, inicialización de servicios
├── core/
│   ├── services/                    # Lógica de negocio (Singletons)
│   │   ├── ai_service.dart          # Gemini API + generación local
│   │   ├── notification_service.dart
│   │   ├── notification_scheduler.dart  # AlarmManager (NUEVO, sin commitear)
│   │   ├── connectivity_service.dart
│   │   ├── quote_api_service.dart   # ZenQuotes / Quotable / Type.fit
│   │   ├── stats_service.dart       # XP, streaks, métricas
│   │   ├── translation_service.dart
│   │   ├── widget_service.dart      # MethodChannel → widget Android
│   │   └── theme_service.dart       # ChangeNotifier, persistencia de tema
│   ├── constants/
│   │   ├── app_strings.dart
│   │   ├── app_colors.dart          # Colores dinámicos desde ThemeService
│   │   ├── app_dimensions.dart
│   │   └── achievements.dart
│   └── theme/
│       ├── theme_models.dart        # AppThemeData
│       └── theme_presets.dart       # Temas predefinidos
├── data/
│   ├── models/
│   │   ├── quote.dart               # Modelo principal de frase
│   │   ├── user_profile.dart        # Perfil + gamificación
│   │   ├── api_quote.dart           # DTO para APIs externas
│   │   ├── daily_stats.dart         # Métricas diarias
│   │   └── notification_schedule.dart  # NUEVO
│   └── database/
│       └── database_helper.dart     # Singleton SQLite, toda la capa de datos
└── presentation/
    ├── screens/
    │   ├── splash_screen.dart
    │   ├── main_navigation.dart     # Bottom nav (Home/Favoritos/Stats/Logros/Config)
    │   ├── home_screen.dart
    │   ├── favorites_screen.dart
    │   ├── stats_screen.dart
    │   ├── achievements_screen.dart
    │   ├── settings_screen.dart
    │   ├── api_settings_screen.dart
    │   ├── notification_settings_screen.dart
    │   ├── theme_selector_screen.dart
    │   └── onboarding/
    │       └── onboarding_screen.dart  # 5 pasos: nombre, retos, tiempos, valores, tono
    └── widgets/
        ├── quote_card.dart          # Tarjeta animada de frase
        ├── xp_bar.dart              # Barra de progreso XP
        └── level_up_dialog.dart     # Modal confetti al subir nivel
```

---

## Stack Tecnológico

| Categoría | Tecnología |
|-----------|-----------|
| Framework | Flutter (Dart 3.2+) |
| State Management | Provider (ChangeNotifier) + estado local |
| Base de datos | sqflite (SQLite) |
| Preferencias | shared_preferences |
| IA | google_generative_ai (Gemini) |
| HTTP | http + dio |
| Notificaciones | flutter_local_notifications + android_alarm_manager_plus |
| Fuentes | google_fonts |
| Compartir | share_plus |
| Traducción | translator |
| Conectividad | connectivity_plus |
| Animaciones | confetti + Flutter animaciones nativas |

---

## Esquema de Base de Datos

### `quotes`
| Campo | Tipo | Notas |
|-------|------|-------|
| id | INTEGER PK | |
| text | TEXT NOT NULL | |
| author | TEXT | |
| category | TEXT | Motivación, Productividad, etc. |
| source | TEXT | 'local' o 'api' |
| language | TEXT | 'es' o 'en' |
| length | INTEGER | chars |
| created_at | TEXT | ISO datetime |
| last_shown | TEXT | NULL si nunca mostrada |
| view_count | INTEGER | |
| is_favorite | INTEGER | 0/1 |

### `user_profile`
| Campo | Tipo | Notas |
|-------|------|-------|
| id | INTEGER PK | |
| name | TEXT | |
| challenges | TEXT | JSON lista |
| preferred_times | TEXT | JSON lista |
| user_values | TEXT | JSON lista |
| tone_preference | TEXT | energetic/calm/direct/balanced |
| created_at | TEXT | |
| level | INTEGER | |
| total_xp | INTEGER | 100 XP = 1 nivel |
| current_streak | INTEGER | días consecutivos |
| max_streak | INTEGER | |

### `notification_schedules` (DB v2)
| Campo | Tipo | Notas |
|-------|------|-------|
| id | INTEGER PK | |
| time | TEXT | "HH:mm" |
| label | TEXT | Mañana/Tarde/Noche |
| days | TEXT | "0,1,2,3,4,5,6" |
| enabled | INTEGER | 0/1 |

### `daily_stats`
| Campo | Tipo | Notas |
|-------|------|-------|
| date | TEXT UNIQUE | "YYYY-MM-DD" |
| quotes_viewed | INTEGER | |
| time_spent_seconds | INTEGER | |
| categories_viewed | TEXT | CSV |
| reflections_written | INTEGER | |

---

## Patrones de Código

- **Singletons:** Todos los servicios (`ServiceName.instance`)
- **ChangeNotifier:** Solo `ThemeService` — UI se reconstruye vía `Provider`
- **Estado local:** El resto de pantallas usan `setState` o `StatefulWidget`
- **Repositorio:** `DatabaseHelper` centraliza todo el acceso a datos
- **toMap/fromMap:** Patrón de serialización en todos los modelos
- **copyWith:** Actualizaciones inmutables en todos los modelos
- **Anti-repetición:** `getRandomQuote()` tiene 7 niveles de prioridad para variar frases
- **Gamificación:** `level = (totalXp / 100).floor() + 1`

---

## Comunicación Android

### Widget (pantalla de inicio)
- **MethodChannel:** `com.example.motivation_pro/widget`
- Métodos: `getQuote`, `refreshQuote`
- Retorna: text, author, category

### Notificaciones
- Canal: `daily_quotes_channel` (importance HIGH)
- AlarmManager para exactitud, BroadcastReceiver para reboot
- Permisos: `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED`

---

## Issues de Seguridad Conocidos

> ⚠️ **NO mergear a producción sin resolver:**

1. **API Key expuesta** — Clave Gemini hardcodeada en `ai_service.dart:11`. Mover a variables de entorno o flutter_secure_storage.
2. **SSL bypass activo** — `quote_api_service.dart` tiene `HttpOverrides` que omite verificación SSL. Marcado "solo desarrollo" pero debe removerse antes de release.
3. **Sin validación de input** — campos de usuario (retos, valores) no son sanitizados.
4. **SQLite sin cifrado** — datos personales en texto plano.

---

## Convenciones del Proyecto

- **Idioma del código:** Comentarios en español, código en inglés (variables/métodos)
- **Nombres de archivos:** snake_case
- **Clases:** PascalCase
- **Servicios:** Siempre singleton con `static final instance`
- **Pantallas:** Sufijo `Screen`, widgets reutilizables sin sufijo especial
- **Colores:** Siempre vía `AppColors.*` (dinámicos desde tema activo)
- **Textos:** Centralizar en `AppStrings` cuando sea posible

---

## Flujo de Inicialización (main.dart)

1. WidgetsFlutterBinding
2. NotificationService.initialize()
3. NotificationScheduler.initialize()
4. WidgetService.initialize()
5. Carga frases iniciales al DB
6. Bloqueo orientación (portrait)
7. AiService.initialize()
8. ThemeService.initialize()
9. Configuración status bar

---

## Notas para Desarrollo

- El proyecto está en **alpha activa** — priorizar estabilidad sobre nuevas features
- Los archivos `notification_scheduler.dart` y `notification_schedule.dart` son nuevos y aún no están commiteados
- iOS no tiene soporte real aún — no probar ni asumir compatibilidad iOS
- Las 5 frases iniciales en español se cargan en el primer arranque via `main.dart`
- El `DatabaseHelper` usa versión 2 con migración; al agregar tablas, incrementar versión y agregar `onUpgrade`
- `AppColors` son **dinámicos** — nunca hardcodear colores hex directamente en widgets
