-- ============================================================
-- Book Club MVP — Initial Database Schema
-- ============================================================

-- Enable required extensions
create extension if not exists "uuid-ossp";

-- ============================================================
-- USERS
-- ============================================================
create table public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null check (char_length(display_name) between 2 and 30),
  avatar_url text,
  timezone text not null default 'UTC',
  created_at timestamptz not null default now()
);

create unique index idx_users_display_name on public.users (lower(display_name));

alter table public.users enable row level security;

create policy "Users can view any profile"
  on public.users for select
  using (true);

create policy "Users can update own profile"
  on public.users for update
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.users for insert
  with check (auth.uid() = id);

-- ============================================================
-- BOOKS
-- ============================================================
create table public.books (
  id uuid primary key default uuid_generate_v4(),
  isbn text,
  title text not null,
  author text not null,
  cover_url text,
  page_count integer,
  description text,
  publisher text,
  published_date text,
  edition_info text,
  created_at timestamptz not null default now()
);

create index idx_books_isbn on public.books (isbn);

alter table public.books enable row level security;

create policy "Anyone can view books"
  on public.books for select
  using (true);

create policy "Authenticated users can insert books"
  on public.books for insert
  with check (auth.role() = 'authenticated');

-- ============================================================
-- CLUBS
-- ============================================================
create table public.clubs (
  id uuid primary key default uuid_generate_v4(),
  name text not null check (char_length(name) between 3 and 50),
  description text check (description is null or char_length(description) <= 200),
  avatar_url text,
  current_book_id uuid references public.books(id) on delete set null,
  invite_code text unique,
  invite_link_token uuid default uuid_generate_v4(),
  invite_expires_at timestamptz,
  created_by uuid not null references public.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create index idx_clubs_invite_code on public.clubs (invite_code);
create index idx_clubs_invite_link_token on public.clubs (invite_link_token);

alter table public.clubs enable row level security;

create policy "Members can view their clubs"
  on public.clubs for select
  using (
    exists (
      select 1 from public.club_members
      where club_members.club_id = clubs.id
        and club_members.user_id = auth.uid()
        and club_members.status = 'accepted'
    )
  );

create policy "Authenticated users can create clubs"
  on public.clubs for insert
  with check (auth.uid() = created_by);

create policy "Club admins can update their club"
  on public.clubs for update
  using (
    exists (
      select 1 from public.club_members
      where club_members.club_id = clubs.id
        and club_members.user_id = auth.uid()
        and club_members.role = 'admin'
    )
  );

-- ============================================================
-- CLUB MEMBERS
-- ============================================================
create table public.club_members (
  id uuid primary key default uuid_generate_v4(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  role text not null default 'member' check (role in ('admin', 'member')),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'declined')),
  reading_format text check (reading_format in ('same_edition', 'diff_edition', 'kindle', 'audiobook', 'other')),
  format_total text,
  custom_endpoint text,
  joined_at timestamptz,
  invited_by uuid references public.users(id) on delete set null
);

create unique index idx_club_members_unique on public.club_members (club_id, user_id);
create index idx_club_members_user on public.club_members (user_id);

alter table public.club_members enable row level security;

create policy "Members can view club membership"
  on public.club_members for select
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.club_members cm
      where cm.club_id = club_members.club_id
        and cm.user_id = auth.uid()
        and cm.status = 'accepted'
    )
  );

create policy "Authenticated users can insert membership"
  on public.club_members for insert
  with check (auth.role() = 'authenticated');

create policy "Members can update own membership"
  on public.club_members for update
  using (user_id = auth.uid());

create policy "Admins can update memberships in their club"
  on public.club_members for update
  using (
    exists (
      select 1 from public.club_members cm
      where cm.club_id = club_members.club_id
        and cm.user_id = auth.uid()
        and cm.role = 'admin'
    )
  );

create policy "Admins can remove members"
  on public.club_members for delete
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.club_members cm
      where cm.club_id = club_members.club_id
        and cm.user_id = auth.uid()
        and cm.role = 'admin'
    )
  );

-- ============================================================
-- CLUB BOOKS (History)
-- ============================================================
create table public.club_books (
  id uuid primary key default uuid_generate_v4(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  book_id uuid not null references public.books(id) on delete cascade,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  set_by uuid not null references public.users(id) on delete cascade,
  default_endpoint integer
);

create index idx_club_books_club on public.club_books (club_id);

alter table public.club_books enable row level security;

create policy "Club members can view book history"
  on public.club_books for select
  using (
    exists (
      select 1 from public.club_members
      where club_members.club_id = club_books.club_id
        and club_members.user_id = auth.uid()
        and club_members.status = 'accepted'
    )
  );

create policy "Club admins can manage book history"
  on public.club_books for insert
  with check (
    exists (
      select 1 from public.club_members
      where club_members.club_id = club_books.club_id
        and club_members.user_id = auth.uid()
        and club_members.role = 'admin'
    )
  );

-- ============================================================
-- READING PROGRESS
-- ============================================================
create table public.reading_progress (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  club_id uuid not null references public.clubs(id) on delete cascade,
  book_id uuid not null references public.books(id) on delete cascade,
  current_page integer,
  current_location integer,
  current_timestamp_sec integer,
  percent_complete float not null default 0.0 check (percent_complete between 0.0 and 100.0),
  updated_at timestamptz not null default now()
);

create unique index idx_reading_progress_unique on public.reading_progress (user_id, club_id, book_id);

alter table public.reading_progress enable row level security;

create policy "Club members can view progress"
  on public.reading_progress for select
  using (
    exists (
      select 1 from public.club_members
      where club_members.club_id = reading_progress.club_id
        and club_members.user_id = auth.uid()
        and club_members.status = 'accepted'
    )
  );

create policy "Users can upsert own progress"
  on public.reading_progress for insert
  with check (auth.uid() = user_id);

create policy "Users can update own progress"
  on public.reading_progress for update
  using (auth.uid() = user_id);

-- ============================================================
-- PROGRESS LOG (append-only)
-- ============================================================
create table public.progress_log (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  book_id uuid not null references public.books(id) on delete cascade,
  club_id uuid references public.clubs(id) on delete set null,
  current_page integer,
  current_location integer,
  current_timestamp_sec integer,
  percent_complete float not null,
  logged_at timestamptz not null default now()
);

create index idx_progress_log_user_book on public.progress_log (user_id, book_id);
create index idx_progress_log_logged_at on public.progress_log (logged_at);

alter table public.progress_log enable row level security;

create policy "Users can view own progress log"
  on public.progress_log for select
  using (auth.uid() = user_id);

create policy "Users can insert own progress log"
  on public.progress_log for insert
  with check (auth.uid() = user_id);

-- ============================================================
-- MARGIN NOTES
-- ============================================================
create table public.margin_notes (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  club_id uuid not null references public.clubs(id) on delete cascade,
  book_id uuid not null references public.books(id) on delete cascade,
  page_number integer,
  location_number integer,
  timestamp_sec integer,
  percent_position float not null check (percent_position between 0.0 and 100.0),
  note_text text not null check (char_length(note_text) <= 500),
  quote_text text check (quote_text is null or char_length(quote_text) <= 300),
  visibility text not null default 'club' check (visibility in ('club', 'private')),
  created_at timestamptz not null default now()
);

create index idx_margin_notes_club_book on public.margin_notes (club_id, book_id);
create index idx_margin_notes_percent on public.margin_notes (percent_position);

alter table public.margin_notes enable row level security;

-- Spoiler gating: users can only see notes at or below their own progress
create policy "Members can view spoiler-gated notes"
  on public.margin_notes for select
  using (
    -- Own private notes are always visible
    (user_id = auth.uid())
    or
    -- Club notes gated by reader's progress percentage
    (
      visibility = 'club'
      and exists (
        select 1 from public.club_members
        where club_members.club_id = margin_notes.club_id
          and club_members.user_id = auth.uid()
          and club_members.status = 'accepted'
      )
      and margin_notes.percent_position <= coalesce(
        (
          select rp.percent_complete
          from public.reading_progress rp
          where rp.user_id = auth.uid()
            and rp.club_id = margin_notes.club_id
            and rp.book_id = margin_notes.book_id
        ),
        0.0
      )
    )
  );

create policy "Users can create own notes"
  on public.margin_notes for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own notes"
  on public.margin_notes for delete
  using (auth.uid() = user_id);

-- ============================================================
-- NOTE REACTIONS
-- ============================================================
create table public.note_reactions (
  id uuid primary key default uuid_generate_v4(),
  note_id uuid not null references public.margin_notes(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  emoji text not null check (emoji in ('💡', '❤️', '😂', '🤔', '👏')),
  created_at timestamptz not null default now()
);

create unique index idx_note_reactions_unique on public.note_reactions (note_id, user_id, emoji);

alter table public.note_reactions enable row level security;

create policy "Members can view reactions on visible notes"
  on public.note_reactions for select
  using (
    exists (
      select 1 from public.margin_notes mn
      where mn.id = note_reactions.note_id
    )
  );

create policy "Users can add reactions"
  on public.note_reactions for insert
  with check (auth.uid() = user_id);

create policy "Users can remove own reactions"
  on public.note_reactions for delete
  using (auth.uid() = user_id);

-- ============================================================
-- NOTE REPLIES
-- ============================================================
create table public.note_replies (
  id uuid primary key default uuid_generate_v4(),
  note_id uuid not null references public.margin_notes(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  reply_text text not null check (char_length(reply_text) <= 280),
  created_at timestamptz not null default now()
);

create index idx_note_replies_note on public.note_replies (note_id);

alter table public.note_replies enable row level security;

create policy "Members can view replies on visible notes"
  on public.note_replies for select
  using (
    exists (
      select 1 from public.margin_notes mn
      where mn.id = note_replies.note_id
    )
  );

create policy "Users can create replies"
  on public.note_replies for insert
  with check (auth.uid() = user_id);

create policy "Users can delete own replies"
  on public.note_replies for delete
  using (auth.uid() = user_id);

-- ============================================================
-- CHAT MESSAGES
-- ============================================================
create table public.chat_messages (
  id uuid primary key default uuid_generate_v4(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  user_id uuid references public.users(id) on delete set null,
  message_type text not null default 'text' check (message_type in ('text', 'system')),
  content text not null check (char_length(content) <= 1000),
  is_spoiler boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_chat_messages_club on public.chat_messages (club_id, created_at desc);

alter table public.chat_messages enable row level security;

create policy "Club members can view messages"
  on public.chat_messages for select
  using (
    exists (
      select 1 from public.club_members
      where club_members.club_id = chat_messages.club_id
        and club_members.user_id = auth.uid()
        and club_members.status = 'accepted'
    )
  );

create policy "Members can send messages"
  on public.chat_messages for insert
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.club_members
      where club_members.club_id = chat_messages.club_id
        and club_members.user_id = auth.uid()
        and club_members.status = 'accepted'
    )
  );

-- ============================================================
-- CHAT READ RECEIPTS
-- ============================================================
create table public.chat_read_receipts (
  user_id uuid not null references public.users(id) on delete cascade,
  club_id uuid not null references public.clubs(id) on delete cascade,
  last_read_message_id uuid references public.chat_messages(id) on delete set null,
  read_at timestamptz not null default now(),
  primary key (user_id, club_id)
);

alter table public.chat_read_receipts enable row level security;

create policy "Members can view read receipts in their clubs"
  on public.chat_read_receipts for select
  using (
    exists (
      select 1 from public.club_members
      where club_members.club_id = chat_read_receipts.club_id
        and club_members.user_id = auth.uid()
        and club_members.status = 'accepted'
    )
  );

create policy "Users can upsert own read receipts"
  on public.chat_read_receipts for insert
  with check (auth.uid() = user_id);

create policy "Users can update own read receipts"
  on public.chat_read_receipts for update
  using (auth.uid() = user_id);

-- ============================================================
-- PERSONAL BOOKS
-- ============================================================
create table public.personal_books (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  book_id uuid not null references public.books(id) on delete cascade,
  shelf text not null default 'reading' check (shelf in ('reading', 'want_to_read', 'finished')),
  reading_format text check (reading_format in ('physical', 'kindle', 'audiobook', 'ebook', 'other')),
  format_total text,
  custom_endpoint text,
  current_page integer,
  current_location integer,
  current_timestamp_sec integer,
  percent_complete float not null default 0.0 check (percent_complete between 0.0 and 100.0),
  started_at timestamptz,
  finished_at timestamptz,
  created_at timestamptz not null default now()
);

create index idx_personal_books_user on public.personal_books (user_id, shelf);

alter table public.personal_books enable row level security;

create policy "Users can view own personal books"
  on public.personal_books for select
  using (auth.uid() = user_id);

create policy "Users can add personal books"
  on public.personal_books for insert
  with check (auth.uid() = user_id);

create policy "Users can update own personal books"
  on public.personal_books for update
  using (auth.uid() = user_id);

create policy "Users can delete own personal books"
  on public.personal_books for delete
  using (auth.uid() = user_id);

-- ============================================================
-- DAILY READING LOG
-- ============================================================
create table public.daily_reading_log (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  book_id uuid not null references public.books(id) on delete cascade,
  source text not null check (source in ('personal', 'club')),
  club_id uuid references public.clubs(id) on delete set null,
  pages_equivalent float not null default 0.0,
  duration_minutes integer,
  logged_date date not null,
  created_at timestamptz not null default now()
);

create index idx_daily_reading_log_user_date on public.daily_reading_log (user_id, logged_date);

alter table public.daily_reading_log enable row level security;

create policy "Users can view own reading log"
  on public.daily_reading_log for select
  using (auth.uid() = user_id);

create policy "Users can insert own reading log"
  on public.daily_reading_log for insert
  with check (auth.uid() = user_id);

-- ============================================================
-- READING STREAKS
-- ============================================================
create table public.reading_streaks (
  user_id uuid primary key references public.users(id) on delete cascade,
  current_streak integer not null default 0,
  longest_streak integer not null default 0,
  last_read_date date,
  grace_day_enabled boolean not null default false,
  grace_day_used_this_week boolean not null default false,
  streak_started_at date
);

alter table public.reading_streaks enable row level security;

create policy "Users can view own streaks"
  on public.reading_streaks for select
  using (auth.uid() = user_id);

create policy "Users can upsert own streaks"
  on public.reading_streaks for insert
  with check (auth.uid() = user_id);

create policy "Users can update own streaks"
  on public.reading_streaks for update
  using (auth.uid() = user_id);

-- ============================================================
-- READING GOALS
-- ============================================================
create table public.reading_goals (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  goal_period text not null check (goal_period in ('weekly', 'monthly', 'yearly')),
  goal_type text not null check (goal_type in ('pages', 'minutes', 'books')),
  target_value integer not null check (target_value > 0),
  week_start_day text default 'MO',
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_reading_goals_user on public.reading_goals (user_id, is_active);

alter table public.reading_goals enable row level security;

create policy "Users can view own goals"
  on public.reading_goals for select
  using (auth.uid() = user_id);

create policy "Users can create own goals"
  on public.reading_goals for insert
  with check (auth.uid() = user_id);

create policy "Users can update own goals"
  on public.reading_goals for update
  using (auth.uid() = user_id);

create policy "Users can delete own goals"
  on public.reading_goals for delete
  using (auth.uid() = user_id);

-- ============================================================
-- GOAL PROGRESS
-- ============================================================
create table public.goal_progress (
  id uuid primary key default uuid_generate_v4(),
  user_id uuid not null references public.users(id) on delete cascade,
  goal_id uuid not null references public.reading_goals(id) on delete cascade,
  period_start date not null,
  period_end date not null,
  current_value float not null default 0.0,
  target_value integer not null,
  completed boolean not null default false
);

create index idx_goal_progress_user_goal on public.goal_progress (user_id, goal_id, period_start);

alter table public.goal_progress enable row level security;

create policy "Users can view own goal progress"
  on public.goal_progress for select
  using (auth.uid() = user_id);

create policy "Users can insert own goal progress"
  on public.goal_progress for insert
  with check (auth.uid() = user_id);

create policy "Users can update own goal progress"
  on public.goal_progress for update
  using (auth.uid() = user_id);

-- ============================================================
-- CLUB MEETINGS
-- ============================================================
create table public.club_meetings (
  id uuid primary key default uuid_generate_v4(),
  club_id uuid not null references public.clubs(id) on delete cascade,
  title text not null,
  description text check (description is null or char_length(description) <= 500),
  meeting_type text not null check (meeting_type in ('in_person', 'virtual', 'hybrid')),
  location_name text,
  location_address text,
  location_lat float,
  location_lng float,
  virtual_link text,
  starts_at timestamptz not null,
  duration_minutes integer not null default 60,
  reading_target_percent float,
  reading_target_page integer,
  recurrence text check (recurrence is null or recurrence in ('weekly', 'biweekly', 'monthly')),
  recurrence_parent_id uuid references public.club_meetings(id) on delete set null,
  reminder_offsets jsonb default '[1440, 60]'::jsonb,
  created_by uuid not null references public.users(id) on delete cascade,
  cancelled boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_club_meetings_club on public.club_meetings (club_id, starts_at);

alter table public.club_meetings enable row level security;

create policy "Club members can view meetings"
  on public.club_meetings for select
  using (
    exists (
      select 1 from public.club_members
      where club_members.club_id = club_meetings.club_id
        and club_members.user_id = auth.uid()
        and club_members.status = 'accepted'
    )
  );

create policy "Club admins can create meetings"
  on public.club_meetings for insert
  with check (
    exists (
      select 1 from public.club_members
      where club_members.club_id = club_meetings.club_id
        and club_members.user_id = auth.uid()
        and club_members.role = 'admin'
    )
  );

create policy "Club admins can update meetings"
  on public.club_meetings for update
  using (
    exists (
      select 1 from public.club_members
      where club_members.club_id = club_meetings.club_id
        and club_members.user_id = auth.uid()
        and club_members.role = 'admin'
    )
  );

-- ============================================================
-- MEETING RSVPS
-- ============================================================
create table public.meeting_rsvps (
  id uuid primary key default uuid_generate_v4(),
  meeting_id uuid not null references public.club_meetings(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  status text not null check (status in ('going', 'maybe', 'not_going')),
  responded_at timestamptz not null default now()
);

create unique index idx_meeting_rsvps_unique on public.meeting_rsvps (meeting_id, user_id);

alter table public.meeting_rsvps enable row level security;

create policy "Club members can view RSVPs"
  on public.meeting_rsvps for select
  using (
    exists (
      select 1 from public.club_meetings cm
      join public.club_members cmem on cmem.club_id = cm.club_id
      where cm.id = meeting_rsvps.meeting_id
        and cmem.user_id = auth.uid()
        and cmem.status = 'accepted'
    )
  );

create policy "Members can RSVP"
  on public.meeting_rsvps for insert
  with check (auth.uid() = user_id);

create policy "Members can update own RSVP"
  on public.meeting_rsvps for update
  using (auth.uid() = user_id);

-- ============================================================
-- STORAGE BUCKETS
-- ============================================================
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('club-avatars', 'club-avatars', true)
on conflict (id) do nothing;

-- Storage policies for avatars
create policy "Anyone can view avatars"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "Users can upload own avatar"
  on storage.objects for insert
  with check (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

create policy "Users can update own avatar"
  on storage.objects for update
  using (bucket_id = 'avatars' and auth.uid()::text = (storage.foldername(name))[1]);

-- Storage policies for club avatars
create policy "Anyone can view club avatars"
  on storage.objects for select
  using (bucket_id = 'club-avatars');

create policy "Authenticated users can upload club avatars"
  on storage.objects for insert
  with check (bucket_id = 'club-avatars' and auth.role() = 'authenticated');

-- ============================================================
-- REALTIME PUBLICATION
-- ============================================================
alter publication supabase_realtime add table public.reading_progress;
alter publication supabase_realtime add table public.chat_messages;
alter publication supabase_realtime add table public.margin_notes;
alter publication supabase_realtime add table public.club_meetings;
alter publication supabase_realtime add table public.meeting_rsvps;
