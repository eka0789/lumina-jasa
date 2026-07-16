begin;

insert into public.categories(id, name, slug, description, sort_order, status) values
  ('51000000-0000-0000-0000-000000000001', 'Perbaikan rumah', 'perbaikan-rumah', 'Perawatan dan perbaikan hunian', 10, 'active'),
  ('51000000-0000-0000-0000-000000000002', 'Kebersihan', 'kebersihan', 'Kebersihan rumah dan tempat usaha', 20, 'active'),
  ('51000000-0000-0000-0000-000000000003', 'Konstruksi', 'konstruksi', 'Renovasi dan pekerjaan konstruksi', 30, 'active'),
  ('51000000-0000-0000-0000-000000000004', 'Jasa digital', 'jasa-digital', 'Desain dan teknologi untuk bisnis', 40, 'active')
on conflict (slug) do nothing;

insert into public.services(id, category_id, name, slug, description, default_duration_minutes, status) values
  ('52000000-0000-0000-0000-000000000001', (select id from public.categories where slug = 'perbaikan-rumah'), 'Servis AC', 'servis-ac', 'Pemeriksaan, cuci, dan perbaikan AC', 90, 'active'),
  ('52000000-0000-0000-0000-000000000002', (select id from public.categories where slug = 'perbaikan-rumah'), 'Perbaikan listrik', 'perbaikan-listrik', 'Instalasi dan gangguan listrik ringan', 120, 'active'),
  ('52000000-0000-0000-0000-000000000003', (select id from public.categories where slug = 'perbaikan-rumah'), 'Perbaikan pipa', 'perbaikan-pipa', 'Kebocoran, sumbatan, dan instalasi air', 120, 'active'),
  ('52000000-0000-0000-0000-000000000004', (select id from public.categories where slug = 'kebersihan'), 'Kebersihan rumah', 'kebersihan-rumah', 'Pembersihan rutin dan mendalam', 180, 'active'),
  ('52000000-0000-0000-0000-000000000005', (select id from public.categories where slug = 'konstruksi'), 'Renovasi ruang', 'renovasi-ruang', 'Renovasi ruang hunian dan usaha', null, 'active'),
  ('52000000-0000-0000-0000-000000000006', (select id from public.categories where slug = 'jasa-digital'), 'Desain grafis', 'desain-grafis', 'Desain identitas dan materi komunikasi', null, 'active')
on conflict (slug) do nothing;

commit;
