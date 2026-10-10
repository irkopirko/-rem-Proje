-- Ink Akademi — MySQL schema (utf8mb4)
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS users (
  id CHAR(36) PRIMARY KEY,
  user_no INT UNSIGNED NOT NULL AUTO_INCREMENT UNIQUE,
  username VARCHAR(20) NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  first_name VARCHAR(120) NOT NULL,
  last_name VARCHAR(120) NOT NULL,
  birth_date DATE NULL,
  role ENUM('student','crew','super_admin') NOT NULL DEFAULT 'student',
  membership_status ENUM(
    'trial','trial_expired','plus','light','life_plus','none'
  ) NOT NULL DEFAULT 'trial',
  membership_expires_at DATETIME NULL,
  profile_photo_url TEXT NULL,
  email_verified_at DATETIME NULL,
  chat_banned TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  deleted_by_user_id CHAR(36) NULL,
  purge_requested_at DATETIME NULL,
  INDEX idx_users_role (role),
  INDEX idx_users_membership (membership_status),
  INDEX idx_users_deleted (deleted_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS refresh_tokens (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  token_hash CHAR(64) NOT NULL,
  expires_at DATETIME NOT NULL,
  revoked_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  INDEX idx_refresh_user (user_id),
  INDEX idx_refresh_hash (token_hash)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS otp_codes (
  id CHAR(36) PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  code_hash CHAR(64) NOT NULL,
  purpose ENUM('register','password_reset','email_change') NOT NULL,
  attempts TINYINT UNSIGNED NOT NULL DEFAULT 0,
  expires_at DATETIME NOT NULL,
  consumed_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_otp_email (email, purpose)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  actor_user_id CHAR(36) NULL,
  action VARCHAR(64) NOT NULL,
  target_type VARCHAR(64) NULL,
  target_id VARCHAR(64) NULL,
  metadata JSON NULL,
  ip_address VARCHAR(45) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_audit_actor (actor_user_id),
  INDEX idx_audit_action (action)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS modules (
  id CHAR(36) PRIMARY KEY,
  module_number DECIMAL(6,2) NOT NULL UNIQUE,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS videos (
  id CHAR(36) PRIMARY KEY,
  module_id CHAR(36) NOT NULL,
  video_number DECIMAL(6,2) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT NULL,
  duration_seconds INT UNSIGNED NOT NULL DEFAULT 0,
  stream_url TEXT NULL,
  thumbnail_url TEXT NULL,
  bunny_video_id VARCHAR(64) NULL UNIQUE,
  status ENUM('awaiting_upload','processing','ready','failed') NOT NULL DEFAULT 'awaiting_upload',
  width INT UNSIGNED NULL,
  height INT UNSIGNED NULL,
  uploaded_by_user_id CHAR(36) NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_module_video (module_id, video_number),
  INDEX idx_videos_module_order (module_id, sort_order),
  INDEX idx_videos_status (status),
  FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS video_progress (
  user_id CHAR(36) NOT NULL,
  video_id CHAR(36) NOT NULL,
  watched_seconds INT UNSIGNED NOT NULL DEFAULT 0,
  last_position_seconds INT UNSIGNED NOT NULL DEFAULT 0,
  completed TINYINT(1) NOT NULL DEFAULT 0,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, video_id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (video_id) REFERENCES videos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS badges (
  id CHAR(36) PRIMARY KEY,
  slug VARCHAR(64) NOT NULL UNIQUE,
  title VARCHAR(120) NOT NULL,
  image_url TEXT NULL,
  description TEXT NULL,
  sort_order INT NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_badges (
  user_id CHAR(36) NOT NULL,
  badge_id CHAR(36) NOT NULL,
  earned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, badge_id),
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (badge_id) REFERENCES badges(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS live_sessions (
  id CHAR(36) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  stream_url TEXT NOT NULL,
  thumbnail_url TEXT NULL,
  starts_at DATETIME NOT NULL,
  ends_at DATETIME NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS product_categories (
  id CHAR(36) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  image_url TEXT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_published TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS products (
  id CHAR(36) PRIMARY KEY,
  category_id CHAR(36) NOT NULL,
  name VARCHAR(255) NOT NULL,
  image_url TEXT NULL,
  explanation TEXT NULL,
  purchase_url TEXT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  FOREIGN KEY (category_id) REFERENCES product_categories(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS product_images (
  id CHAR(36) PRIMARY KEY,
  product_id CHAR(36) NOT NULL,
  mime_type VARCHAR(40) NOT NULL,
  byte_size INT UNSIGNED NOT NULL,
  data MEDIUMBLOB NULL,
  storage_key VARCHAR(255) NULL,
  sort_order INT NOT NULL DEFAULT 0,
  uploaded_by_user_id CHAR(36) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_product_images_product (product_id, sort_order),
  FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS homework (
  id CHAR(36) PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  explanation TEXT NOT NULL,
  created_by CHAR(36) NOT NULL,
  due_at DATETIME NULL,
  assign_to_all TINYINT(1) NOT NULL DEFAULT 1,
  is_published TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (created_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS homework_images (
  id CHAR(36) PRIMARY KEY,
  homework_id CHAR(36) NOT NULL,
  mime_type VARCHAR(40) NOT NULL,
  byte_size INT UNSIGNED NOT NULL,
  data MEDIUMBLOB NULL,
  storage_key VARCHAR(255) NULL,
  sort_order INT NOT NULL DEFAULT 0,
  uploaded_by_user_id CHAR(36) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_homework_images_homework (homework_id, sort_order),
  FOREIGN KEY (homework_id) REFERENCES homework(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- One active photo per user. Replacing it deletes the previous row and its CDN file.
CREATE TABLE IF NOT EXISTS profile_photos (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  mime_type VARCHAR(40) NOT NULL,
  byte_size INT UNSIGNED NOT NULL,
  data MEDIUMBLOB NULL,
  storage_key VARCHAR(255) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_profile_photos_user (user_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS homework_assignments (
  id CHAR(36) PRIMARY KEY,
  homework_id CHAR(36) NOT NULL,
  student_id CHAR(36) NOT NULL,
  status ENUM(
    'pending','submitted','grading','graded_pass','graded_revise'
  ) NOT NULL DEFAULT 'pending',
  assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_hw_student (homework_id, student_id),
  FOREIGN KEY (homework_id) REFERENCES homework(id) ON DELETE CASCADE,
  FOREIGN KEY (student_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS homework_submissions (
  id CHAR(36) PRIMARY KEY,
  assignment_id CHAR(36) NOT NULL,
  file_url TEXT NOT NULL,
  file_mime VARCHAR(64) NOT NULL,
  submitted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (assignment_id) REFERENCES homework_assignments(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS homework_grades (
  id CHAR(36) PRIMARY KEY,
  assignment_id CHAR(36) NOT NULL,
  score TINYINT UNSIGNED NOT NULL,
  feedback TEXT NULL,
  graded_by CHAR(36) NOT NULL,
  graded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  is_revision_grade TINYINT(1) NOT NULL DEFAULT 0,
  FOREIGN KEY (assignment_id) REFERENCES homework_assignments(id) ON DELETE CASCADE,
  FOREIGN KEY (graded_by) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS chat_threads (
  id CHAR(36) PRIMARY KEY,
  student_id CHAR(36) NOT NULL UNIQUE,
  crew_user_id CHAR(36) NULL,
  last_message_at DATETIME NULL,
  FOREIGN KEY (student_id) REFERENCES users(id),
  FOREIGN KEY (crew_user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS chat_messages (
  id CHAR(36) PRIMARY KEY,
  thread_id CHAR(36) NOT NULL,
  sender_id CHAR(36) NOT NULL,
  body TEXT NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (thread_id) REFERENCES chat_threads(id) ON DELETE CASCADE,
  FOREIGN KEY (sender_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS app_content (
  content_key VARCHAR(64) PRIMARY KEY,
  content_value TEXT NOT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS subscription_events (
  id CHAR(36) PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  product_id VARCHAR(120) NOT NULL,
  event_type ENUM('trial_start','purchase','renew','expire','cancel') NOT NULL,
  raw_payload JSON NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS community_messages (
  id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id CHAR(36) NOT NULL,
  body TEXT NOT NULL,
  created_at DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  deleted_at DATETIME NULL,
  deleted_by_user_id CHAR(36) NULL,
  INDEX idx_community_user (user_id),
  FOREIGN KEY (user_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS community_reports (
  id CHAR(36) PRIMARY KEY,
  message_id BIGINT UNSIGNED NOT NULL,
  reporter_id CHAR(36) NOT NULL,
  reason VARCHAR(500) NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  resolved_at DATETIME NULL,
  resolved_by_user_id CHAR(36) NULL,
  UNIQUE KEY uq_report (message_id, reporter_id),
  INDEX idx_reports_open (resolved_at),
  FOREIGN KEY (message_id) REFERENCES community_messages(id) ON DELETE CASCADE,
  FOREIGN KEY (reporter_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS user_blocks (
  blocker_id CHAR(36) NOT NULL,
  blocked_id CHAR(36) NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (blocker_id, blocked_id),
  FOREIGN KEY (blocker_id) REFERENCES users(id),
  FOREIGN KEY (blocked_id) REFERENCES users(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
