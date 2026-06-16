# Prueba Técnica — Banco Guayaquil

Módulo de administración de movimientos de cuenta.  
Stack: **SwiftUI (iOS 17+)** + **.NET 10 Web API**

---

## Ejecutar el Backend (.NET Core)

**Requisito:** .NET 10 SDK

```bash
cd BancoGYE_API
dotnet restore
dotnet run
```

API disponible en `http://localhost:8080`  
Swagger UI en `http://localhost:8080` (root)

> Perfil alternativo HTTPS: `https://localhost:7298` / `http://localhost:5220`  
> Para usar perfil HTTPS: `dotnet run --launch-profile https`

### Endpoints

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/movements` | Lista paginada de movimientos |
| GET | `/api/movements/{id}` | Detalle de un movimiento |

**Query params de `/api/movements`:**
- `page` (default: 1)
- `pageSize` (default: 20, max: 100)
- `from` / `to` — ISO 8601 date range
- `search` — texto libre (nombre, descripción, referencia)

### Correr tests backend

```bash
cd BancoGYE_API.Tests
dotnet test
```

41 tests — DataStore, Repository, Service, Controller (integración con WebApplicationFactory).

---

## Tests iOS

**Requisito:** Xcode 16+ con esquema `BancoGYETests`

```bash
# Desde Xcode: Cmd+U
# O desde CLI:
xcodebuild test -project BancoGYE_iOS/BancoGYE.xcodeproj \
  -scheme BancoGYE \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

34 tests — organizados en 4 suites:

| Suite | Tests | Cubre |
|-------|-------|-------|
| `BiometricViewModelTests` | 7 | Estados de autenticación (éxito, fallo, cancelación, sin biometría, retry) |
| `MovementsViewModelTests` | 12 | Carga inicial, paginación, refresh, búsqueda, filtros, agrupación por fecha |
| `ArchivedMovementStoreTests` | 7 | Persistencia Core Data (archivar, desarchivar, duplicados, integridad de datos) |
| `DateGroupTests` | 8 | Lógica de agrupación temporal (hoy, esta semana, últimos 15/30 días, más antiguo) |

---

## Ejecutar la App iOS

**Requisito:** Xcode 16+, iOS 17+ (simulador o dispositivo)

```bash
cd BancoGYE_iOS
xcodegen generate   # solo si se modificó project.yml
open BancoGYE.xcodeproj
```

1. Seleccionar esquema `BancoGYE`
2. Seleccionar simulador (iPhone 15 Pro recomendado)
3. `Cmd+R` para correr

> La biometría en simulador: ir a **Features → Face ID → Enrolled**, luego **Matching Face**

---

## Arquitectura iOS

**Patrón:** MVVM + Clean Architecture (capas separadas)

```
Sources/
├── App/                    # Entry point, RootView
├── Features/
│   ├── Auth/               # BiometricService, BiometricViewModel, BiometricView
│   └── Movements/
│       ├── Views/          # MovementsView, MovementDetailView
│       └── ViewModels/     # MovementsViewModel
├── Core/
│   ├── Domain/             # Movement model, DateGroup, enums
│   ├── Network/            # APIClient, MovementsRepository
│   └── Persistence/        # ArchivedMovementStore (Core Data)
└── Components/
    ├── Cards/              # MovementCardView, SearchBarView
    ├── Filters/            # FilterTabsView
    └── States/             # LoadingView, EmptyStateView, ErrorStateView
```

---

## Arquitectura Backend

**Patrón:** Layered Architecture (Controller → Service → Repository → DataStore)

```
BancoGYE_API/
├── Controllers/    # MovementsController
├── Services/       # IMovementsService, MovementsService
├── Repositories/   # IMovementsRepository, MovementsRepository
├── Data/           # MovementsDataStore (seed 1500 movimientos en memoria)
├── Models/         # Movement, MovementType, MovementStatus
├── DTOs/           # MovementResponse, PagedResponse, MovementsQueryRequest
└── Middleware/     # GlobalExceptionMiddleware
```

---

## Decisiones técnicas

### Biometría
`LocalAuthentication.LAContext` con `deviceOwnerAuthenticationWithBiometrics`.  
Maneja: éxito, cancelación, fallo, dispositivo sin biometría.

Fallback a passcode implementado en dos casos:
- Usuario toca "Ingresar contraseña" en el diálogo de Face ID (`LAError.userFallback`) → se abre pantalla de passcode del sistema vía `.deviceOwnerAuthentication`
- Face ID bloqueado por intentos fallidos (`LAError.biometryLockout`) → fallback automático a passcode

### Paginación
- iOS carga página inicial (20 items, últimos 30 días).
- Scroll infinito: al aparecer el último item del grupo, dispara `loadMore()`.
- Backend pagina con `SKIP/TAKE` sobre colección en memoria.

### Persistencia local (archivados)
Core Data con modelo programático (sin `.xcdatamodel`).  
`ArchivedMovementStore` es singleton.  
Archivar = insertar entity. Desarchivar = borrar entity.  
**Por qué Core Data:** integrado en iOS, sin dependencias externas, soporte offline nativo.

### Datos mock
`MovementsDataStore` genera 1500 movimientos con `Random(seed: 42)` al arrancar.  
Distribuidos aleatoriamente en los últimos 90 días.

### Cómo escalaría a 50.000 movimientos
- **Backend:** reemplazar in-memory store con base de datos real (PostgreSQL/SQL Server) + índices en `Date`, `ContactName`. Cursor-based pagination en vez de OFFSET.
- **iOS:** `NSFetchedResultsController` o `LazyVStack` con paginación virtual. Cache local con TTL. Prefetch predictivo.

### Concurrencia iOS
`async/await` + `@MainActor` para actualizaciones de UI.  
Debounce de 400ms en búsqueda para evitar requests innecesarios.

---

## Evidencia Gráfica

Video demo de la app (flujo completo: biometría, movimientos, archivado):  
[Ver evidencia en Google Drive](https://drive.google.com/file/d/1o5jsLkOLkWuRwV3XoDL2kq_p8vrknCe9/view?usp=sharing)

---

## Librerías utilizadas

| Lib | Uso |
|-----|-----|
| `LocalAuthentication` | Biometría nativa iOS |
| `CoreData` | Persistencia local archivados |
| `SwiftUI` | UI |
| `Swashbuckle.AspNetCore` | Swagger/OpenAPI en .NET |

Sin dependencias de terceros en iOS.
