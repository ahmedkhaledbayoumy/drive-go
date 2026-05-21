-- ═══════════════════════════════════════════════════════════════════════
-- Drive Go - Database Schema
-- ═══════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────
-- 1. PROFILES (extends Supabase auth.users)
-- ─────────────────────────────────────────────────
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text not null,
  phone text,
  account_type text not null check (account_type in ('customer','individualOwner','dealership')),
  avatar_url text,
  business_name text,
  banner_url text,
  verified boolean default false,
  city text,
  created_at timestamptz default now()
);
alter table profiles enable row level security;
create policy "Profiles viewable by authenticated" on profiles for select to authenticated using (true);
create policy "Users update own profile" on profiles for update to authenticated using (auth.uid() = id);
create policy "Users create own profile" on profiles for insert to authenticated with check (auth.uid() = id);

-- ─────────────────────────────────────────────────
-- 2. CARS
-- ─────────────────────────────────────────────────
create table cars (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references profiles(id) on delete cascade,
  brand text not null,
  model text not null,
  year integer not null,
  color text not null,
  transmission text not null check (transmission in ('manual','automatic')),
  fuel_type text not null check (fuel_type in ('petrol','diesel','hybrid','electric')),
  city text not null,
  price_per_day numeric not null,
  price_per_week numeric,
  price_per_month numeric,
  description text not null,
  photos text[] default array[]::text[],
  status text not null default 'available' check (status in ('available','pendingConfirmation','booked')),
  created_at timestamptz default now()
);
alter table cars enable row level security;
create policy "Cars viewable by everyone" on cars for select using (true);
create policy "Owners insert own cars" on cars for insert to authenticated with check (auth.uid() = owner_id);
create policy "Owners update own cars" on cars for update to authenticated using (auth.uid() = owner_id);
create policy "Owners delete own cars" on cars for delete to authenticated using (auth.uid() = owner_id);

-- ─────────────────────────────────────────────────
-- 3. BOOKINGS
-- ─────────────────────────────────────────────────
create table bookings (
  id uuid primary key default gen_random_uuid(),
  car_id uuid not null references cars(id) on delete cascade,
  customer_id uuid not null references profiles(id) on delete cascade,
  owner_id uuid not null references profiles(id) on delete cascade,
  start_date timestamptz not null,
  end_date timestamptz not null,
  total_price numeric not null,
  with_driver boolean default false,
  pickup_location text,
  status text not null default 'pending' check (status in ('pending','confirmed','declined','completed','cancelled')),
  payment_status text not null default 'pending' check (payment_status in ('pending','paid','refunded')),
  created_at timestamptz default now()
);
alter table bookings enable row level security;
create policy "Users view own bookings" on bookings for select to authenticated using (auth.uid() = customer_id or auth.uid() = owner_id);
create policy "Customers create bookings" on bookings for insert to authenticated with check (auth.uid() = customer_id);
create policy "Participants update bookings" on bookings for update to authenticated using (auth.uid() = customer_id or auth.uid() = owner_id);

-- ─────────────────────────────────────────────────
-- 4. REVIEWS
-- ─────────────────────────────────────────────────
create table reviews (
  id uuid primary key default gen_random_uuid(),
  dealership_id uuid not null references profiles(id) on delete cascade,
  customer_id uuid not null references profiles(id) on delete cascade,
  booking_id uuid references bookings(id) on delete set null,
  rating integer not null check (rating >= 1 and rating <= 5),
  comment text not null,
  created_at timestamptz default now()
);
alter table reviews enable row level security;
create policy "Reviews viewable by everyone" on reviews for select using (true);
create policy "Customers create reviews" on reviews for insert to authenticated with check (auth.uid() = customer_id);

-- ─────────────────────────────────────────────────
-- 5. CHAT MESSAGES
-- ─────────────────────────────────────────────────
create table chat_messages (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references bookings(id) on delete cascade,
  sender_id uuid not null references profiles(id) on delete cascade,
  text text not null,
  read boolean default false,
  created_at timestamptz default now()
);
alter table chat_messages enable row level security;
create policy "View messages for own bookings" on chat_messages for select to authenticated using (
  exists (select 1 from bookings where bookings.id = chat_messages.booking_id and (bookings.customer_id = auth.uid() or bookings.owner_id = auth.uid()))
);
create policy "Send messages for own bookings" on chat_messages for insert to authenticated with check (
  auth.uid() = sender_id and exists (select 1 from bookings where bookings.id = chat_messages.booking_id and (bookings.customer_id = auth.uid() or bookings.owner_id = auth.uid()))
);

-- ─────────────────────────────────────────────────
-- 6. NOTIFICATIONS
-- ─────────────────────────────────────────────────
create table notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  title text not null,
  body text not null,
  type text not null check (type in ('bookingRequest','bookingConfirmed','bookingDeclined','statusChange','reviewPrompt')),
  related_id text,
  read boolean default false,
  created_at timestamptz default now()
);
alter table notifications enable row level security;
create policy "View own notifications" on notifications for select to authenticated using (auth.uid() = user_id);
create policy "Update own notifications" on notifications for update to authenticated using (auth.uid() = user_id);

-- ─────────────────────────────────────────────────
-- 7. SAVED CARS (favorites)
-- ─────────────────────────────────────────────────
create table saved_cars (
  user_id uuid not null references profiles(id) on delete cascade,
  car_id uuid not null references cars(id) on delete cascade,
  saved_at timestamptz default now(),
  primary key (user_id, car_id)
);
alter table saved_cars enable row level security;
create policy "View own saved cars" on saved_cars for select to authenticated using (auth.uid() = user_id);
create policy "Save cars" on saved_cars for insert to authenticated with check (auth.uid() = user_id);
create policy "Unsave cars" on saved_cars for delete to authenticated using (auth.uid() = user_id);

-- ─────────────────────────────────────────────────
-- INDEXES (performance)
-- ─────────────────────────────────────────────────
create index idx_cars_owner_id on cars(owner_id);
create index idx_cars_status on cars(status);
create index idx_cars_city on cars(city);
create index idx_bookings_customer_id on bookings(customer_id);
create index idx_bookings_owner_id on bookings(owner_id);
create index idx_chat_messages_booking_id on chat_messages(booking_id);
create index idx_notifications_user_id on notifications(user_id);