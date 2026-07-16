-- Levio sample data seed.
--
-- Run after supabase/schema.sql in a development or staging Supabase project.
-- For private demo data to appear in-app, replace demo_user_id below with the
-- UUID of the Supabase Auth user you use for demos. Community posts/comments
-- are visible to any authenticated user; logs, schedules, recovery sessions,
-- likes, and group memberships are owner-scoped by RLS.

do $$
declare
  demo_user_id text := '00000000-0000-4000-8000-000000000001';
  maya_user_id text := '00000000-0000-4000-8000-000000000002';
  daniel_user_id text := '00000000-0000-4000-8000-000000000003';
  priya_user_id text := '00000000-0000-4000-8000-000000000004';
  carlos_user_id text := '00000000-0000-4000-8000-000000000005';
begin
  insert into public.users (id, name, email, age, profile_image)
  values
    (demo_user_id, 'Levio Demo Member', 'demo@levio.local', 68, 'images/711128.png'),
    (maya_user_id, 'Maya P.', null, 64, 'images/711128.png'),
    (daniel_user_id, 'Daniel R.', null, 71, 'images/711128.png'),
    (priya_user_id, 'Priya S.', null, 59, 'images/711128.png'),
    (carlos_user_id, 'Carlos M.', null, 66, 'images/711128.png')
  on conflict (id) do update
    set name = excluded.name,
        email = excluded.email,
        age = excluded.age,
        profile_image = excluded.profile_image,
        updated_at = timezone('utc', now());

  insert into public.logs (
    id,
    user_id,
    title,
    data,
    event_time,
    symptom,
    severity,
    created_at,
    updated_at
  )
  values
    (
      'demo-log-001',
      demo_user_id,
      'Morning hand tremor',
      json_build_object(
        'time', '07:15, 10 June 2026',
        'symptom', 'Morning hand tremor before first walk',
        'severity', 'Moderate'
      )::text,
      '07:15, 10 June 2026',
      'Morning hand tremor before first walk',
      'Moderate',
      '2026-06-10 07:15:00+00',
      '2026-06-10 07:15:00+00'
    ),
    (
      'demo-log-002',
      demo_user_id,
      'Left shoulder stiffness',
      json_build_object(
        'time', '10:40, 10 June 2026',
        'symptom', 'Left shoulder stiffness after sitting',
        'severity', 'Mild'
      )::text,
      '10:40, 10 June 2026',
      'Left shoulder stiffness after sitting',
      'Mild',
      '2026-06-10 10:40:00+00',
      '2026-06-10 10:40:00+00'
    ),
    (
      'demo-log-003',
      demo_user_id,
      'Afternoon fatigue',
      json_build_object(
        'time', '15:25, 11 June 2026',
        'symptom', 'Afternoon fatigue after errands',
        'severity', 'Moderate'
      )::text,
      '15:25, 11 June 2026',
      'Afternoon fatigue after errands',
      'Moderate',
      '2026-06-11 15:25:00+00',
      '2026-06-11 15:25:00+00'
    ),
    (
      'demo-log-004',
      demo_user_id,
      'Freezing at doorway',
      json_build_object(
        'time', '08:30, 12 June 2026',
        'symptom', 'Brief freezing at kitchen doorway',
        'severity', 'Severe'
      )::text,
      '08:30, 12 June 2026',
      'Brief freezing at kitchen doorway',
      'Severe',
      '2026-06-12 08:30:00+00',
      '2026-06-12 08:30:00+00'
    ),
    (
      'demo-log-005',
      demo_user_id,
      'Soft voice',
      json_build_object(
        'time', '13:10, 13 June 2026',
        'symptom', 'Soft voice during phone call',
        'severity', 'Mild'
      )::text,
      '13:10, 13 June 2026',
      'Soft voice during phone call',
      'Mild',
      '2026-06-13 13:10:00+00',
      '2026-06-13 13:10:00+00'
    ),
    (
      'demo-log-006',
      demo_user_id,
      'Sleep disruption',
      json_build_object(
        'time', '23:05, 13 June 2026',
        'symptom', 'Restless sleep and vivid dreams',
        'severity', 'Moderate'
      )::text,
      '23:05, 13 June 2026',
      'Restless sleep and vivid dreams',
      'Moderate',
      '2026-06-13 23:05:00+00',
      '2026-06-13 23:05:00+00'
    ),
    (
      'demo-log-007',
      demo_user_id,
      'Balance confidence',
      json_build_object(
        'time', '09:00, 14 June 2026',
        'symptom', 'Felt steady during hallway walk',
        'severity', 'Very Mild'
      )::text,
      '09:00, 14 June 2026',
      'Felt steady during hallway walk',
      'Very Mild',
      '2026-06-14 09:00:00+00',
      '2026-06-14 09:00:00+00'
    ),
    (
      'demo-log-008',
      demo_user_id,
      'Evening dyskinesia',
      json_build_object(
        'time', '18:45, 14 June 2026',
        'symptom', 'Evening dyskinesia while preparing dinner',
        'severity', 'Moderate'
      )::text,
      '18:45, 14 June 2026',
      'Evening dyskinesia while preparing dinner',
      'Moderate',
      '2026-06-14 18:45:00+00',
      '2026-06-14 18:45:00+00'
    )
  on conflict (id) do update
    set user_id = excluded.user_id,
        title = excluded.title,
        data = excluded.data,
        event_time = excluded.event_time,
        symptom = excluded.symptom,
        severity = excluded.severity,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at;

  insert into public.schedules (
    id,
    user_id,
    title,
    data,
    details,
    days,
    created_at,
    updated_at
  )
  values
    (
      'demo-schedule-001',
      demo_user_id,
      'Carbidopa-Levodopa',
      json_build_object(
        'name', 'Carbidopa-Levodopa',
        'details', '25/100 mg, 1 tablet at 7:00 AM, noon, and 5:00 PM',
        'days', 'Everyday'
      )::text,
      '25/100 mg, 1 tablet at 7:00 AM, noon, and 5:00 PM',
      'Everyday',
      '2026-06-01 07:00:00+00',
      '2026-06-01 07:00:00+00'
    ),
    (
      'demo-schedule-002',
      demo_user_id,
      'Rasagiline',
      json_build_object(
        'name', 'Rasagiline',
        'details', '1 mg with breakfast',
        'days', 'Everyday'
      )::text,
      '1 mg with breakfast',
      'Everyday',
      '2026-06-01 07:05:00+00',
      '2026-06-01 07:05:00+00'
    ),
    (
      'demo-schedule-003',
      demo_user_id,
      'Amantadine',
      json_build_object(
        'name', 'Amantadine',
        'details', '100 mg mid-morning',
        'days', 'Monday, Wednesday, Friday'
      )::text,
      '100 mg mid-morning',
      'Monday, Wednesday, Friday',
      '2026-06-01 10:00:00+00',
      '2026-06-01 10:00:00+00'
    ),
    (
      'demo-schedule-004',
      demo_user_id,
      'Vitamin D3',
      json_build_object(
        'name', 'Vitamin D3',
        'details', 'Daily supplement with lunch',
        'days', 'Everyday'
      )::text,
      'Daily supplement with lunch',
      'Everyday',
      '2026-06-01 12:00:00+00',
      '2026-06-01 12:00:00+00'
    ),
    (
      'demo-schedule-005',
      demo_user_id,
      'Melatonin',
      json_build_object(
        'name', 'Melatonin',
        'details', 'Evening sleep routine reminder',
        'days', 'Sunday, Tuesday, Thursday'
      )::text,
      'Evening sleep routine reminder',
      'Sunday, Tuesday, Thursday',
      '2026-06-01 21:00:00+00',
      '2026-06-01 21:00:00+00'
    )
  on conflict (id) do update
    set user_id = excluded.user_id,
        title = excluded.title,
        data = excluded.data,
        details = excluded.details,
        days = excluded.days,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at;

  insert into public.medication_events (
    id,
    user_id,
    schedule_id,
    medication_name,
    scheduled_at,
    taken_at,
    status,
    client_updated_at,
    last_mutation_id
  )
  values
    ('demo-medication-event-001', demo_user_id, 'demo-schedule-001', 'Carbidopa-Levodopa', '2026-06-10 07:00:00+00', '2026-06-10 07:04:00+00', 'taken', '2026-06-10 07:04:00+00', 'seed-medication-001'),
    ('demo-medication-event-002', demo_user_id, 'demo-schedule-001', 'Carbidopa-Levodopa', '2026-06-10 12:00:00+00', '2026-06-10 12:11:00+00', 'taken', '2026-06-10 12:11:00+00', 'seed-medication-002'),
    ('demo-medication-event-003', demo_user_id, 'demo-schedule-001', 'Carbidopa-Levodopa', '2026-06-11 07:00:00+00', '2026-06-11 07:02:00+00', 'taken', '2026-06-11 07:02:00+00', 'seed-medication-003'),
    ('demo-medication-event-004', demo_user_id, 'demo-schedule-002', 'Rasagiline', '2026-06-11 08:00:00+00', '2026-06-11 08:06:00+00', 'taken', '2026-06-11 08:06:00+00', 'seed-medication-004'),
    ('demo-medication-event-005', demo_user_id, 'demo-schedule-001', 'Carbidopa-Levodopa', '2026-06-12 07:00:00+00', '2026-06-12 07:03:00+00', 'taken', '2026-06-12 07:03:00+00', 'seed-medication-005'),
    ('demo-medication-event-006', demo_user_id, 'demo-schedule-003', 'Amantadine', '2026-06-12 10:00:00+00', null, 'skipped', '2026-06-12 10:30:00+00', 'seed-medication-006'),
    ('demo-medication-event-007', demo_user_id, 'demo-schedule-001', 'Carbidopa-Levodopa', '2026-06-13 07:00:00+00', '2026-06-13 07:15:00+00', 'taken', '2026-06-13 07:15:00+00', 'seed-medication-007'),
    ('demo-medication-event-008', demo_user_id, 'demo-schedule-001', 'Carbidopa-Levodopa', '2026-06-14 07:00:00+00', '2026-06-14 07:05:00+00', 'taken', '2026-06-14 07:05:00+00', 'seed-medication-008')
  on conflict (id) do update
    set schedule_id = excluded.schedule_id,
        medication_name = excluded.medication_name,
        scheduled_at = excluded.scheduled_at,
        taken_at = excluded.taken_at,
        status = excluded.status,
        client_updated_at = excluded.client_updated_at,
        last_mutation_id = excluded.last_mutation_id;

  insert into public.recovery_sessions (
    id,
    user_id,
    type,
    video_id,
    title,
    completed_at,
    created_at,
    updated_at
  )
  values
    ('demo-recovery-001', demo_user_id, 'physical', 'AZV3_NfcpVs', 'Sit ''n'' Fit Workout', '2026-06-09 16:00:00+00', '2026-06-09 16:00:00+00', '2026-06-09 16:00:00+00'),
    ('demo-recovery-002', demo_user_id, 'speech', '0ndTdBnVwFY', 'LSVT LOUD Introduction', '2026-06-09 17:15:00+00', '2026-06-09 17:15:00+00', '2026-06-09 17:15:00+00'),
    ('demo-recovery-003', demo_user_id, 'physical', 'HHtgtNmBivo', 'Chair Workout for Balance', '2026-06-10 16:20:00+00', '2026-06-10 16:20:00+00', '2026-06-10 16:20:00+00'),
    ('demo-recovery-004', demo_user_id, 'physical', '4wB43bbSdm8', 'Seated Workout', '2026-06-11 09:30:00+00', '2026-06-11 09:30:00+00', '2026-06-11 09:30:00+00'),
    ('demo-recovery-005', demo_user_id, 'speech', 'dzKy4vKp5_I', 'Voice Exercises with Rachel', '2026-06-11 11:00:00+00', '2026-06-11 11:00:00+00', '2026-06-11 11:00:00+00'),
    ('demo-recovery-006', demo_user_id, 'physical', 'G5OvzAORfuc', 'PWR!Moves + Aerobic', '2026-06-12 15:30:00+00', '2026-06-12 15:30:00+00', '2026-06-12 15:30:00+00'),
    ('demo-recovery-007', demo_user_id, 'speech', 'kGZYg19rYCU', 'SPEAK OUT! Program Overview', '2026-06-12 16:30:00+00', '2026-06-12 16:30:00+00', '2026-06-12 16:30:00+00'),
    ('demo-recovery-008', demo_user_id, 'physical', 'zIFtb-R24Ec', 'Strong & Steady', '2026-06-13 14:00:00+00', '2026-06-13 14:00:00+00', '2026-06-13 14:00:00+00'),
    ('demo-recovery-009', demo_user_id, 'speech', 'O0k_3tsrVYA', 'SPEAK OUT! Lesson 4', '2026-06-13 16:40:00+00', '2026-06-13 16:40:00+00', '2026-06-13 16:40:00+00'),
    ('demo-recovery-010', demo_user_id, 'physical', 'pgtGOgVIhqc', 'LSVT BIG Movements', '2026-06-14 10:30:00+00', '2026-06-14 10:30:00+00', '2026-06-14 10:30:00+00'),
    ('demo-recovery-011', demo_user_id, 'physical', 'QbWyxn8XE-I', 'Exercise Essentials: Intro', '2026-06-14 15:10:00+00', '2026-06-14 15:10:00+00', '2026-06-14 15:10:00+00'),
    ('demo-recovery-012', demo_user_id, 'speech', 'L8bkqvf6TRs', 'LSVT LOUD Vocal Therapy', '2026-06-14 17:05:00+00', '2026-06-14 17:05:00+00', '2026-06-14 17:05:00+00')
  on conflict (id) do update
    set user_id = excluded.user_id,
        type = excluded.type,
        video_id = excluded.video_id,
        title = excluded.title,
        completed_at = excluded.completed_at,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at;

  insert into public.community_posts (
    id,
    user_id,
    user_name,
    profile_image,
    content,
    category,
    likes,
    created_at,
    updated_at
  )
  values
    (
      'demo-post-001',
      maya_user_id,
      'Maya P.',
      'images/711128.png',
      'Tried a seated workout before breakfast today and logged it right away. The streak count makes it easier to notice what I actually completed.',
      'Exercise Tips',
      0,
      '2026-06-14 08:25:00+00',
      '2026-06-14 08:25:00+00'
    ),
    (
      'demo-post-002',
      daniel_user_id,
      'Daniel R.',
      'images/711128.png',
      'Question for the group: what helps you remember afternoon medication when the day gets busy? I am trying a phone alarm plus keeping the schedule screen updated.',
      'Questions',
      0,
      '2026-06-14 11:10:00+00',
      '2026-06-14 11:10:00+00'
    ),
    (
      'demo-post-003',
      priya_user_id,
      'Priya S.',
      'images/711128.png',
      'Speech practice felt less awkward after repeating one short lesson three times this week. Recording the session helped me see the habit forming.',
      'Speech Therapy',
      0,
      '2026-06-14 13:45:00+00',
      '2026-06-14 13:45:00+00'
    ),
    (
      'demo-post-004',
      carlos_user_id,
      'Carlos M.',
      'images/711128.png',
      'I added a note to my symptom log when freezing happened near the kitchen doorway. Seeing the time next to the note gave me something concrete to discuss at my next visit.',
      'Daily Living',
      0,
      '2026-06-14 16:20:00+00',
      '2026-06-14 16:20:00+00'
    ),
    (
      'demo-post-005',
      demo_user_id,
      'Levio Demo Member',
      'images/711128.png',
      'This week I am pairing one balance video with one voice lesson. Small sessions are easier to keep consistent than saving everything for the weekend.',
      'General',
      0,
      '2026-06-14 18:10:00+00',
      '2026-06-14 18:10:00+00'
    ),
    (
      'demo-post-006',
      maya_user_id,
      'Maya P.',
      'images/711128.png',
      'Win for today: I used the medication overview before leaving home and caught a missed lunch reminder before it became a problem.',
      'Daily Living',
      0,
      '2026-06-15 08:30:00+00',
      '2026-06-15 08:30:00+00'
    )
  on conflict (id) do update
    set user_id = excluded.user_id,
        user_name = excluded.user_name,
        profile_image = excluded.profile_image,
        content = excluded.content,
        category = excluded.category,
        is_hidden = false,
        is_flagged = false,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at;

  insert into public.community_comments (
    id,
    post_id,
    user_id,
    user_name,
    profile_image,
    content,
    created_at,
    updated_at
  )
  values
    ('demo-comment-001', 'demo-post-001', demo_user_id, 'Levio Demo Member', 'images/711128.png', 'Logging right after the video is helping me too. I forget if I wait until evening.', '2026-06-14 09:00:00+00', '2026-06-14 09:00:00+00'),
    ('demo-comment-002', 'demo-post-001', carlos_user_id, 'Carlos M.', 'images/711128.png', 'I like using the chair workouts on low energy days.', '2026-06-14 09:20:00+00', '2026-06-14 09:20:00+00'),
    ('demo-comment-003', 'demo-post-002', priya_user_id, 'Priya S.', 'images/711128.png', 'The schedule list plus a label on my water bottle has been useful.', '2026-06-14 11:42:00+00', '2026-06-14 11:42:00+00'),
    ('demo-comment-004', 'demo-post-002', maya_user_id, 'Maya P.', 'images/711128.png', 'I put the reminder after lunch instead of before. Fewer false alarms that way.', '2026-06-14 12:15:00+00', '2026-06-14 12:15:00+00'),
    ('demo-comment-005', 'demo-post-003', daniel_user_id, 'Daniel R.', 'images/711128.png', 'Repeating the same lesson made it easier for me to notice progress.', '2026-06-14 14:05:00+00', '2026-06-14 14:05:00+00'),
    ('demo-comment-006', 'demo-post-004', demo_user_id, 'Levio Demo Member', 'images/711128.png', 'That is exactly the kind of context I want to remember before appointments.', '2026-06-14 16:55:00+00', '2026-06-14 16:55:00+00'),
    ('demo-comment-007', 'demo-post-005', maya_user_id, 'Maya P.', 'images/711128.png', 'Small and repeatable has been the best approach for me too.', '2026-06-14 18:40:00+00', '2026-06-14 18:40:00+00'),
    ('demo-comment-008', 'demo-post-006', daniel_user_id, 'Daniel R.', 'images/711128.png', 'That overview has become part of my morning check-in.', '2026-06-15 09:10:00+00', '2026-06-15 09:10:00+00')
  on conflict (id) do update
    set post_id = excluded.post_id,
        user_id = excluded.user_id,
        user_name = excluded.user_name,
        profile_image = excluded.profile_image,
        content = excluded.content,
        is_flagged = false,
        created_at = excluded.created_at,
        updated_at = excluded.updated_at;

  insert into public.community_post_likes (post_id, user_id, created_at)
  values
    ('demo-post-001', demo_user_id, '2026-06-14 09:05:00+00'),
    ('demo-post-001', daniel_user_id, '2026-06-14 09:10:00+00'),
    ('demo-post-001', priya_user_id, '2026-06-14 09:15:00+00'),
    ('demo-post-002', demo_user_id, '2026-06-14 11:25:00+00'),
    ('demo-post-002', maya_user_id, '2026-06-14 11:28:00+00'),
    ('demo-post-003', demo_user_id, '2026-06-14 14:00:00+00'),
    ('demo-post-003', carlos_user_id, '2026-06-14 14:20:00+00'),
    ('demo-post-004', demo_user_id, '2026-06-14 16:45:00+00'),
    ('demo-post-004', priya_user_id, '2026-06-14 16:50:00+00'),
    ('demo-post-005', maya_user_id, '2026-06-14 18:30:00+00'),
    ('demo-post-005', daniel_user_id, '2026-06-14 18:35:00+00'),
    ('demo-post-005', carlos_user_id, '2026-06-14 18:50:00+00'),
    ('demo-post-006', demo_user_id, '2026-06-15 08:40:00+00'),
    ('demo-post-006', priya_user_id, '2026-06-15 08:55:00+00')
  on conflict (post_id, user_id) do update
    set created_at = excluded.created_at;

  update public.community_posts post
    set likes = like_counts.total,
        updated_at = post.updated_at
  from (
    select post_id, count(*)::integer as total
    from public.community_post_likes
    where post_id in (
      'demo-post-001',
      'demo-post-002',
      'demo-post-003',
      'demo-post-004',
      'demo-post-005',
      'demo-post-006'
    )
    group by post_id
  ) as like_counts
  where post.id = like_counts.post_id;

  insert into public.community_group_memberships (
    group_id,
    user_id,
    created_at,
    updated_at
  )
  values
    ('movement', demo_user_id, '2026-06-10 08:00:00+00', '2026-06-10 08:00:00+00'),
    ('newly-diagnosed', demo_user_id, '2026-06-10 08:05:00+00', '2026-06-10 08:05:00+00'),
    ('movement', maya_user_id, '2026-06-10 08:10:00+00', '2026-06-10 08:10:00+00'),
    ('caregivers', daniel_user_id, '2026-06-10 08:15:00+00', '2026-06-10 08:15:00+00'),
    ('movement', priya_user_id, '2026-06-10 08:20:00+00', '2026-06-10 08:20:00+00'),
    ('newly-diagnosed', carlos_user_id, '2026-06-10 08:25:00+00', '2026-06-10 08:25:00+00')
  on conflict (group_id, user_id) do update
    set created_at = excluded.created_at,
        updated_at = excluded.updated_at;
end $$;
