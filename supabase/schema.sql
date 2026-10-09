-- Esquema de Inventario TI + Órdenes de compra (Pixel Graphic / Ambiente Azul)
-- Ya está aplicado en el proyecto Supabase. Se deja aquí como respaldo y documentación.

create table public.empresas (
  id bigint generated always as identity primary key,
  nombre text not null unique,
  created_at timestamptz not null default now()
);

create table public.app_usuarios (
  email text primary key,
  created_at timestamptz not null default now()
);

create or replace function public.es_usuario_autorizado()
returns boolean language sql stable security definer set search_path = ''
as $$
  select exists (select 1 from public.app_usuarios u
                 where lower(u.email) = lower(coalesce(auth.jwt() ->> 'email', '')));
$$;
revoke all on function public.es_usuario_autorizado() from public, anon;
grant execute on function public.es_usuario_autorizado() to authenticated;

create table public.equipos (
  id uuid primary key default gen_random_uuid(),
  empresa_id bigint not null references public.empresas(id) on delete restrict,
  codigo text not null,
  tipo text not null default 'Otro',
  marca text not null default '',
  serial text not null default '',
  especificaciones text not null default '',
  so text not null default '',
  usuario text not null default '',
  ubicacion text not null default '',
  responsable text not null default '',
  estado text not null default 'Activo',
  fecha_compra date,
  factura text not null default '',
  valor_compra numeric(14,2),
  proveedor text not null default '',
  meses_garantia integer not null default 12 check (meses_garantia >= 0),
  frecuencia_meses integer not null default 6 check (frecuencia_meses > 0),
  lic_office text not null default 'N/A' check (lic_office in ('Sí','No','N/A')),
  lic_windows text not null default 'N/A' check (lic_windows in ('Sí','No','N/A')),
  lic_antivirus text not null default 'N/A' check (lic_antivirus in ('Sí','No','N/A')),
  lic_adobe text not null default 'N/A' check (lic_adobe in ('Sí','No','N/A')),
  lic_autocad text not null default 'N/A' check (lic_autocad in ('Sí','No','N/A')),
  lic_sketchup text not null default 'N/A' check (lic_sketchup in ('Sí','No','N/A')),
  observaciones text not null default '',
  created_at timestamptz not null default now(),
  unique (empresa_id, codigo)
);

create table public.historial (
  id uuid primary key default gen_random_uuid(),
  equipo_id uuid not null references public.equipos(id) on delete cascade,
  fecha date not null default current_date,
  tipo text not null,
  descripcion text not null default '',
  repuestos text not null default '',
  costo numeric(14,2),
  tecnico text not null default '',
  observaciones text not null default '',
  created_at timestamptz not null default now()
);

create table public.licencias (
  id uuid primary key default gen_random_uuid(),
  equipo_id uuid not null references public.equipos(id) on delete cascade,
  software text not null,
  tipo_licencia text not null default 'Perpetua',
  clave text not null default '',
  fecha_compra date,
  vigencia_meses integer check (vigencia_meses is null or vigencia_meses > 0),
  costo numeric(14,2),
  proveedor text not null default '',
  observaciones text not null default '',
  created_at timestamptz not null default now()
);

create table public.proveedores (
  id uuid primary key default gen_random_uuid(),
  empresa_id bigint not null references public.empresas(id) on delete restrict,
  nombre text not null,
  nit text not null default '',
  contacto text not null default '',
  telefono text not null default '',
  email text not null default '',
  direccion text not null default '',
  observaciones text not null default '',
  created_at timestamptz not null default now()
);

create table public.ordenes_compra (
  id uuid primary key default gen_random_uuid(),
  empresa_id bigint not null references public.empresas(id) on delete restrict,
  numero text not null,
  proveedor_id uuid references public.proveedores(id) on delete set null,
  proveedor_nombre text not null,
  fecha date not null default current_date,
  fecha_entrega date,
  estado text not null default 'Pendiente' check (estado in ('Pendiente','Enviada','Recibida','Cancelada')),
  condicion_pago text not null default 'Contado' check (condicion_pago in ('Contado','30 días','60 días')),
  aplica_iva boolean not null default true,
  correos_destino text not null default '',
  observaciones text not null default '',
  created_at timestamptz not null default now(),
  unique (empresa_id, numero)
);

create table public.ordenes_items (
  id uuid primary key default gen_random_uuid(),
  orden_id uuid not null references public.ordenes_compra(id) on delete cascade,
  posicion integer not null default 1,
  descripcion text not null,
  cantidad numeric(14,2) not null default 1 check (cantidad >= 0),
  valor_unitario numeric(14,2) not null default 0 check (valor_unitario >= 0)
);

create index on public.equipos (empresa_id);
create index on public.historial (equipo_id, fecha desc);
create index on public.licencias (equipo_id);
create index on public.proveedores (empresa_id);
create index on public.ordenes_compra (empresa_id, fecha desc);
create index on public.ordenes_compra (proveedor_id);
create index on public.ordenes_items (orden_id);

-- Seguridad: solo usuarios con sesión Y con correo en app_usuarios
alter table public.empresas enable row level security;
alter table public.app_usuarios enable row level security;   -- sin políticas: nadie la lee desde la API
alter table public.equipos enable row level security;
alter table public.historial enable row level security;
alter table public.licencias enable row level security;
alter table public.proveedores enable row level security;
alter table public.ordenes_compra enable row level security;
alter table public.ordenes_items enable row level security;

do $$ declare t text; begin
  foreach t in array array['empresas','equipos','historial','licencias','proveedores','ordenes_compra','ordenes_items'] loop
    execute format('create policy acceso_autorizado on public.%I for all to authenticated
                    using ((select public.es_usuario_autorizado()))
                    with check ((select public.es_usuario_autorizado()))', t);
  end loop;
end $$;

insert into public.empresas (nombre) values ('Pixel Graphic'), ('Ambiente Azul');
insert into public.app_usuarios (email) values ('sistemas@pixel-g.com');

-- Para autorizar a otra persona:
--   insert into public.app_usuarios (email) values ('persona@empresa.com');
