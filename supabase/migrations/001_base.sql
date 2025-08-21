begin;

-- Core tables
create table if not exists properties (
  id uuid primary key,
  name text not null,
  address text,
  unit text,
  notes text,
  active boolean default true,
  created_at timestamptz default now()
);

create table if not exists people (
  id uuid primary key,
  name text not null,
  email text unique,
  role text check (role in ('Owner','Admin','Member')) not null,
  created_at timestamptz default now()
);

create table if not exists categories (
  id uuid primary key,
  "group" text check ("group" in ('Tenant','Repairs','Operations','Admin','Compliance')) not null,
  name text not null
);

create table if not exists timelogs (
  id uuid primary key,
  person_id uuid references people(id),
  property_id uuid not null references properties(id),
  category_id uuid not null references categories(id),
  started_at timestamptz,
  ended_at timestamptz,
  hours numeric,
  notes text,
  created_at timestamptz default now()
);

create table if not exists mileage (
  id uuid primary key,
  person_id uuid references people(id),
  property_id uuid references properties(id),
  date date,
  origin text,
  destination text,
  miles numeric,
  purpose text,
  created_at timestamptz default now()
);

create table if not exists expenses (
  id uuid primary key,
  person_id uuid references people(id),
  property_id uuid not null references properties(id),
  category_id uuid not null references categories(id),
  date date,
  vendor text,
  amount numeric,
  payment_method text check (payment_method in ('Card','Cash','ACH','Check')),
  notes text,
  created_at timestamptz default now()
);

create table if not exists receipts (
  id uuid primary key,
  expense_id uuid references expenses(id) on delete cascade,
  file_url text not null,
  ocr_json jsonb,
  verified boolean default false,
  created_at timestamptz default now(),
  constraint receipts_expense_unique unique (expense_id)
);

create table if not exists tenants (
  id uuid primary key,
  property_id uuid references properties(id),
  name text,
  email text,
  phone text,
  lease_start date,
  lease_end date,
  rent numeric,
  deposit numeric,
  created_at timestamptz default now()
);

create table if not exists tenant_events (
  id uuid primary key,
  property_id uuid references properties(id),
  tenant_id uuid references tenants(id),
  date timestamptz,
  type text check (type in ('Inquiry','Screening','Lease','Renewal','Complaint','Notice')),
  notes text,
  created_at timestamptz default now()
);

create table if not exists vendors (
  id uuid primary key,
  name text unique,
  contact text,
  default_category_id uuid references categories(id)
);

create table if not exists audit_log (
  id uuid primary key,
  entity text,
  entity_id uuid,
  action text check (action in ('CREATE','UPDATE','DELETE')),
  who uuid references people(id),
  "when" timestamptz default now(),
  before jsonb,
  after jsonb
);

-- Row Level Security: permissive for authenticated for now
alter table properties enable row level security;
alter table people enable row level security;
alter table categories enable row level security;
alter table timelogs enable row level security;
alter table mileage enable row level security;
alter table expenses enable row level security;
alter table receipts enable row level security;
alter table tenants enable row level security;
alter table tenant_events enable row level security;
alter table vendors enable row level security;
alter table audit_log enable row level security;

-- Helper to create permissive policies for a table
do $$
declare
  t text;
  tables text[] := array[
    'properties','people','categories','timelogs','mileage','expenses','receipts',
    'tenants','tenant_events','vendors','audit_log'
  ];
begin
  foreach t in array tables loop
    execute format('create policy %L on %I for select to authenticated using (true);', t || '_select_auth', t);
    execute format('create policy %L on %I for insert to authenticated with check (true);', t || '_insert_auth', t);
    execute format('create policy %L on %I for update to authenticated using (true) with check (true);', t || '_update_auth', t);
    execute format('create policy %L on %I for delete to authenticated using (true);', t || '_delete_auth', t);
  end loop;
end$$;

commit;

