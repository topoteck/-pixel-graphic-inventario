# Pixel Graphic · Inventario TI y órdenes de compra

Aplicación web de un solo archivo (`index.html`) que guarda sus datos en Supabase.
Equipos, historial de mantenimientos, licencias, proveedores y órdenes de compra (PDF, IVA 19 %, firmas).

## Publicar en GitHub Pages

1. Crea un repositorio en GitHub y sube **todo el contenido de esta carpeta**.
2. En el repositorio: **Settings → Pages → Build and deployment → Deploy from a branch**, rama `main`, carpeta `/ (root)`.
3. En unos minutos queda en `https://TU-USUARIO.github.io/NOMBRE-DEL-REPO/`.
4. En **Supabase → Authentication → URL Configuration** pon esa dirección como **Site URL** y agrégala en **Redirect URLs**.
   Sin este paso, los correos de confirmación y de acceso apuntan a una dirección que no existe.

## Primer ingreso

1. Abre la aplicación y pulsa **Crear cuenta** con `sistemas@pixel-g.com` y una contraseña de 6 o más caracteres.
2. Confirma el correo que llega y vuelve a la aplicación para **Entrar**.

Solo pueden ver datos los correos que estén en la tabla `app_usuarios`. Para autorizar a otra persona,
en Supabase → SQL Editor:

```sql
insert into public.app_usuarios (email) values ('persona@empresa.com');
```

## Qué hay en la base de datos

| Tabla | Contenido |
|---|---|
| `empresas` | Pixel Graphic y Ambiente Azul (un solo proyecto para ambos) |
| `equipos` | Ficha, garantía, mantenimiento y las 6 licencias (Sí / No / N/A) |
| `historial` | Mantenimientos, reparaciones y mejoras |
| `licencias` | Software por equipo con vigencia |
| `proveedores` | Directorio |
| `ordenes_compra` / `ordenes_items` | Órdenes y sus ítems |

`supabase/schema.sql` es el respaldo del esquema (ya está aplicado en el proyecto).

## Notas de seguridad

- La llave `sb_publishable_…` dentro de `index.html` es pública por diseño. Lo que protege los datos es el inicio de
  sesión más las políticas RLS: sin sesión, o con un correo que no está en `app_usuarios`, no se puede leer ni escribir nada.
- En un repositorio **público**, el logo y las firmas (van incrustados en `index.html`) son visibles para cualquiera.
  Si eso no es aceptable, usa un repositorio privado con Cloudflare Pages o Netlify, que funcionan igual.

## Limitaciones conocidas

- **Envío de correo:** el navegador no puede adjuntar archivos por sí solo. El botón descarga el PDF y abre tu programa de
  correo con el mensaje redactado; el PDF se adjunta a mano. El envío 100 % automático requiere una función en Supabase
  con un servicio de correo (por ejemplo Resend).
- El correo de confirmación de Supabase usa su servicio integrado, que tiene un límite bajo de mensajes por hora.
- Para usar la app con **Ambiente Azul**, cambia `EMPRESA_NOMBRE` al inicio del bloque de Supabase en `index.html`.
