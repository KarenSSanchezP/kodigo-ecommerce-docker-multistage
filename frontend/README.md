# KODIGO Store — Frontend E-commerce

Aplicación web de comercio electrónico desarrollada con **Next.js 16 (App Router), React, TypeScript y CSS responsive**, conectada a una API REST en **Laravel 12** con MySQL y pagos en modo de prueba mediante Stripe Checkout.

El proyecto permite explorar productos, registrar clientes, gestionar un carrito y crear pedidos. La confirmación de pago proviene del backend al recibir un webhook válido de Stripe; regresar de Stripe a la aplicación **no** marca una compra como pagada.

## Tecnologías y arquitectura

| Capa | Tecnología | Función |
|---|---|---|
| Frontend | Next.js 16, React, TypeScript | Catálogo, cuenta, carrito y pedidos |
| Lecturas | React Server Components, `fetch` | Consulta de productos y órdenes desde el servidor |
| Mutaciones | Next.js Server Actions | Registro, login, logout, creación y cancelación de órdenes, inicio del pago |
| Autenticación | JWT en cookie `httpOnly` | Sesión del cliente sin exponer el token a JavaScript del navegador |
| Estado del carrito | React y almacenamiento local | Selección y cantidades previas a la creación de una orden |
| API REST | Laravel 12 y PHP 8.4 | Autorización, precios, inventario y estados de pedidos |
| Base de datos | MySQL 8.4 | Persistencia de usuarios, productos y compras |
| Pagos | Stripe Checkout (test mode) | Página de pago externa; confirmación mediante webhook firmado |

Flujo general:

```text
Navegador
  └─ Next.js 16 (http://localhost:3000)
       ├─ Server Components → lectura de API
       ├─ Server Actions → mutaciones autenticadas
       ├─ Cookie httpOnly → sesión JWT
       └─ Carrito del cliente → selección provisional
              │
              ▼
       Laravel API (http://127.0.0.1:8091/api/v1)
              ├─ MySQL (órdenes, productos, usuarios)
              └─ Stripe Checkout → webhook firmado → actualización del pago
```

**Backend del proyecto:** https://github.com/KarenSSanchezP/api-ecommerce-kodigo

## Requisitos

- Node.js compatible con Next.js 16 (mínimo 20.9) y npm.
- Git.
- API Laravel en ejecución y accesible desde el servidor Next.js.
- Para ejecutar el backend local: Docker Desktop, Compose y, en Windows, se recomienda WSL2 con integración Docker.
- Una cuenta o sandbox de **Stripe en modo de prueba** es opcional para recorrer el pago. El catálogo y los pedidos no dependen de configurar Stripe.

## Variables de entorno

El archivo `.env.example` documenta la URL base de la API:

```dotenv
API_BASE_URL=http://127.0.0.1:8091/api/v1
```

`API_BASE_URL` cumple la función de **BASE_URL de la API**. Se utiliza desde código del servidor Next.js y no lleva el prefijo `NEXT_PUBLIC_`.

Para crear la configuración local en Windows PowerShell:

```powershell
Copy-Item .env.example .env.local
```

En Linux/macOS:

```bash
cp .env.example .env.local
```

La URL debe apuntar a una API accesible **desde el entorno donde se ejecuta Next.js**. Si la aplicación se ejecuta dentro de contenedores, `127.0.0.1` no identifica el contenedor Laravel; se debe usar el nombre del servicio de la red de Docker.

No incluyas claves privadas, JWT, secretos de Stripe o el archivo `.env.local` en Git.

## Instalación y ejecución

### 1. Iniciar Laravel

Sigue las instrucciones del [repositorio backend](https://github.com/KarenSSanchezP/api-ecommerce-kodigo). En una instalación que ya tenga configurado el entorno y la base de datos:

```bash
cd ~/kodigo/api-ecommerce-kodigo
docker compose up -d
docker compose ps
```

Verifica que la API devuelva productos en http://127.0.0.1:8091/api/v1/products y consulta Swagger en http://127.0.0.1:8091/api/documentation.

**No ejecutes migraciones destructivas ni `docker compose down -v` en un entorno con datos que deban conservarse.**

### 2. Ejecutar Next.js

```bash
git clone https://github.com/KarenSSanchezP/frontend-ecommerce-kodigo.git
cd frontend-ecommerce-kodigo
npm ci
cp .env.example .env.local
npm run dev
```

En PowerShell reemplaza `cp` por `Copy-Item` si lo prefieres. Abre http://localhost:3000.

### 3. Comprobar la compilación de producción

```bash
npm run lint
npx tsc --noEmit
npm run build
npm run start
```

Para ejecutar `npm run start`, libera el puerto 3000 si continúa activo `npm run dev`.

## Páginas principales

| Ruta | Acceso | Descripción |
|---|---|---|
| `/` | Público | Inicio y selección de productos |
| `/catalogo` | Público | Catálogo de productos |
| `/productos/[id]` | Público | Detalle, precio y existencias |
| `/registro` | Público | Registro de cliente |
| `/login` | Público | Inicio de sesión |
| `/cuenta` | Autenticado | Información del cliente y cierre de sesión |
| `/carrito` | Público | Carrito, cantidades y subtotal |
| `/checkout` | Autenticado | Resumen y creación de una orden |
| `/pedidos` | Autenticado | Historial de órdenes del cliente |
| `/pedidos/[id]` | Autenticado, solo propietario | Detalle, estado, cancelación cuando corresponda y acceso a Stripe Checkout |

## Endpoints consumidos

Todos los endpoints siguientes se encuentran bajo `/api/v1` y se documentan en Swagger:

| Método | Endpoint | Uso |
|---|---|---|
| `GET` | `/products` | Obtener productos |
| `GET` | `/products/{id}` | Consultar un producto |
| `POST` | `/auth/register` | Crear cuenta |
| `POST` | `/auth/login` | Obtener sesión JWT |
| `GET` | `/auth/me` | Consultar el cliente autenticado |
| `POST` | `/auth/logout` | Cerrar la sesión |
| `POST` | `/orders` | Crear orden y reservar inventario |
| `GET` | `/orders` | Consultar historial |
| `GET` | `/orders/{id}` | Consultar detalle |
| `POST` | `/orders/{id}/cancel` | Cancelar una orden elegible |
| `POST` | `/orders/{id}/checkout` | Crear o recuperar sesión Stripe Checkout |

El endpoint `POST /webhooks/stripe` lo consume **Stripe**, no el navegador. La firma se comprueba en Laravel.

## Decisiones de seguridad y resiliencia

- Las consultas de la API se realizan desde Server Components; las operaciones que modifican datos se gestionan mediante Server Actions.
- Las sesiones JWT se almacenan en cookies `httpOnly`, `SameSite=Lax` y `Secure` cuando la aplicación se ejecuta en producción con HTTPS.
- Los endpoints protegidos envían `Authorization: Bearer ...` desde el servidor, no desde JavaScript del navegador.
- El carrito guarda únicamente una selección provisional en el cliente. Laravel calcula nuevamente importes y verifica existencias dentro de la transacción de creación de órdenes.
- El sistema no presupone que visitar la URL `?stripe=success` confirme el pago. El estado mostrado proviene de la orden registrada en Laravel.
- La API verifica los webhooks de Stripe, comprueba la correspondencia del pedido y registra los eventos procesados para evitar aplicar dos veces el mismo evento.
- Las pantallas incluyen límites de carga (`loading.tsx`), manejo de errores (`error.tsx`) y límites `Suspense` en el catálogo y otras vistas.
- Después de mutaciones relevantes se emplea `revalidatePath` para evitar mostrar información obsoleta.
- No se reintenta automáticamente la creación de órdenes ante resultados ambiguos, para evitar pedidos duplicados.

## Evidencia de rendimiento (Lighthouse)

Mediciones de referencia en la **página inicial**, con una compilación de producción y Lighthouse 13.5.0, realizadas el **2 de noviembre de 2026**:

| Indicador | Móvil | Escritorio |
|---|---:|---:|
| Performance | 96 | 100 |
| Accessibility | 93 | 93 |
| Best Practices | 100 | 100 |
| SEO | 100 | 100 |
| FCP | 0.8 s | 0.3 s |
| LCP | 1.8 s | 0.5 s |
| TBT | 210 ms | 0 ms |
| CLS | 0 | 0 |

Estos resultados son **mediciones de laboratorio locales**, no métricas de usuarios reales. Para una entrega reproducible se deben conservar los reportes PDF originales y, tras correcciones de accesibilidad, generar una nueva medición. La evaluación debe incluir rutas representativas además del inicio cuando sea posible.

## Comprobaciones del flujo de compra

1. Consultar el catálogo y abrir el detalle de un producto.
2. Registrar una cuenta e iniciar sesión.
3. Agregar un producto al carrito y revisar el subtotal.
4. Crear un pedido. Laravel valida el inventario y registra el estado `pending`.
5. Iniciar Stripe Checkout en modo de prueba, completar la operación con una tarjeta de prueba oficial y regresar a `/pedidos/[id]`.
6. Confirmar que el backend cambió el estado a `paid` **después** de recibir y validar el webhook.
7. Reenviar el mismo evento original y comprobar que no cambian el stock, el estado del pago ni el número de eventos procesados.

**Prueba local realizada:** pedido de prueba #3, pago simulado de USD 15.99 y reenvío del evento `checkout.session.completed` sin cambios adicionales de inventario (29 unidades antes y después del reenvío). Estas comprobaciones no son prueba de un pago con dinero real.

## Limitaciones y despliegue

- El backend configurado en `127.0.0.1` es local; una instalación remota de Next.js no podrá acceder a esa URL. Para publicar el frontend se necesita una API desplegada en un host accesible, preferiblemente con HTTPS y medidas de seguridad de producción.
- Las credenciales de sandbox de Stripe pueden expirar, deben utilizarse claves vigentes y un receptor de webhooks configurado para nuevas pruebas.
- Los pagos reales, datos comerciales, impuestos, envío y políticas de devolución quedan fuera del alcance de esta versión.
- Lighthouse puntúa una ejecución concreta, por lo que, diferentes dispositivos, redes y cargas pueden producir resultados distintos.

## Repositorios

- Frontend: https://github.com/KarenSSanchezP/frontend-ecommerce-kodigo
- Backend: https://github.com/KarenSSanchezP/api-ecommerce-kodigo
