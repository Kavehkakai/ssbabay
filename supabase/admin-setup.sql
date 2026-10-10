-- Run this only AFTER creating the Supabase Auth user with email admin@ssbabay.local.
-- The password is intentionally not stored in source control.
insert into public.admin_users (user_id)
select id from auth.users where lower(email) = lower('admin@ssbabay.local')
on conflict (user_id) do nothing;

-- Confirm the admin membership was added (should return one row).
select u.id, u.email, a.created_at
from auth.users u
join public.admin_users a on a.user_id = u.id
where lower(u.email) = lower('admin@ssbabay.local');
