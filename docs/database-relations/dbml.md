// OLS API schema — paste into https://dbdiagram.io
// Reflects TypeORM entities after Content→Media, Media→Asset rename
// and PersonalGoal→LearningGoal, SubCategory→SubLearningGoal rename

Project OLS {
  database_type: "Oracle"
  Note: "Learnable items = Media. Stored files = Asset. Main category = LearningGoal; sub-category = SubLearningGoal."
}

// ─── Users ───────────────────────────────────────────────────────────────────

Table User {
  id varchar(36) [pk]
  externalId varchar(255) [not null]
  email varchar(255) [not null]
  displayName varchar(255)
  avatarUrl varchar(2000)
  followerCount int [not null, default: 0]
  followingCount int [not null, default: 0]
  createdAt timestamp [not null]
  updatedAt timestamp [not null]
  deletedAt timestamp

  indexes {
    email
    externalId
    deletedAt
  }
}

// ─── Master data ─────────────────────────────────────────────────────────────

Table LearningGoal {
  id varchar(36) [pk]
  title varchar(255) [not null]
  description text
  createdAt timestamp [not null]
  updatedAt timestamp [not null]
  deletedAt timestamp

  indexes {
    deletedAt
  }
}

Table SubLearningGoal {
  id varchar(36) [pk]
  learningGoalId varchar(36) [not null, ref: > LearningGoal.id]
  title varchar(100) [not null]
  createdAt timestamp [not null]
  updatedAt timestamp [not null]
  deletedAt timestamp

  indexes {
    learningGoalId
    (learningGoalId, title)
    deletedAt
  }
}

Table Tag {
  id varchar(36) [pk]
  title varchar(100) [not null, unique]
  createdAt timestamp [not null]
  updatedAt timestamp [not null]
}

Table LearningSubjectGroup {
  id varchar(36) [pk]
  title varchar(100) [not null, unique]
  sequence int [not null, default: 0]
  createdAt timestamp [not null]
  updatedAt timestamp [not null]
  deletedAt timestamp

  indexes {
    deletedAt
  }
}

Table EducationLevel {
  id varchar(36) [pk]
  title varchar(100) [not null, unique]
  sequence int [not null, default: 0]
  createdAt timestamp [not null]
  updatedAt timestamp [not null]
  deletedAt timestamp

  indexes {
    deletedAt
  }
}

Table GradeLevel {
  id varchar(36) [pk]
  educationLevelId varchar(36) [not null, ref: > EducationLevel.id]
  title varchar(100) [not null]
  sequence int [not null, default: 0]
  createdAt timestamp [not null]
  updatedAt timestamp [not null]
  deletedAt timestamp

  indexes {
    (educationLevelId, title) [unique]
    educationLevelId
    deletedAt
  }
}

// ─── Asset (stored files) ────────────────────────────────────────────────────

Table Asset {
  id varchar(36) [pk]
  originalFilename varchar(255) [not null]
  size int [not null]
  durationMs int
  mimeType varchar(100) [not null]
  objectKey varchar(255) [not null, unique]
  bucket varchar(255) [not null]
  createdAt timestamp [not null]
  updatedAt timestamp [not null]
}

// ─── Media (learnable catalog items) ─────────────────────────────────────────

Table Media {
  id varchar(36) [pk]
  userId varchar(36) [not null, ref: > User.id]
  status varchar(25) [not null, default: "DRAFT"]
  type varchar(25) [not null]
  educationLevel varchar(25) [not null]
  gradeLevel varchar(25) [not null]
  coverAssetId varchar(36) [ref: > Asset.id]
  externalMediaId varchar(255)
  durationSeconds int
  likeCount int [not null, default: 0]
  title varchar(255) [not null]
  description text [not null]
  publishedAt timestamp
  createdAt timestamp [not null]
  updatedAt timestamp [not null]
  deletedAt timestamp

  indexes {
    userId
    status
    type
    educationLevel
    gradeLevel
    (status, publishedAt)
    deletedAt
  }
}

Table MediaTag {
  mediaId varchar(36) [pk, ref: > Media.id]
  tagId varchar(36) [pk, ref: > Tag.id]

  indexes {
    tagId
  }
}

Table MediaSubLearningGoal {
  mediaId varchar(36) [pk, ref: > Media.id]
  subLearningGoalId varchar(36) [pk, ref: > SubLearningGoal.id]
  priority int [not null, note: "1=PRIMARY, 2=SECONDARY, 3=MENTIONED"]

  indexes {
    subLearningGoalId
  }
}

Table VideoMedia {
  id varchar(36) [pk]
  mediaId varchar(36) [not null, unique, ref: - Media.id]
  assetId varchar(36) [not null, ref: > Asset.id]
  embedUrl varchar(2000)
}

Table ArticleMedia {
  id varchar(36) [pk]
  mediaId varchar(36) [not null, unique, ref: - Media.id]
  body text [not null]
  assetId varchar(36) [ref: > Asset.id]
}

Table DocumentMedia {
  id varchar(36) [pk]
  mediaId varchar(36) [not null, unique, ref: - Media.id]
  assetId varchar(36) [not null, ref: > Asset.id]
}

Table EbookMedia {
  id varchar(36) [pk]
  mediaId varchar(36) [not null, unique, ref: - Media.id]
  assetId varchar(36) [not null, ref: > Asset.id]
}

// ─── Course structure ────────────────────────────────────────────────────────

Table Course {
  id varchar(36) [pk]
  userId varchar(36) [not null, ref: > User.id]
  subLearningGoalId varchar(36) [not null, ref: > SubLearningGoal.id]
  title varchar(255) [not null]
  description text
  level varchar(50) [not null]
  status varchar(25) [not null, default: "DRAFT"]
  coverAssetId varchar(36) [ref: > Asset.id]
  publishedAt timestamp
  createdAt timestamp [not null]
  updatedAt timestamp [not null]
  deletedAt timestamp

  indexes {
    userId
    subLearningGoalId
    status
    (status, publishedAt)
    deletedAt
  }
}

Table CourseGradeLevel {
  courseId varchar(36) [pk, ref: > Course.id]
  gradeLevel number [pk, note: 'CHECK between 1 and 12']
}

Table CourseLearningSubjectGroup {
  courseId varchar(36) [pk, ref: > Course.id]
  learningSubjectGroupId varchar(36) [pk, ref: > LearningSubjectGroup.id]

  indexes {
    learningSubjectGroupId
  }
}

Table Lesson {
  id varchar(36) [pk]
  courseId varchar(36) [not null, ref: > Course.id]
  title varchar(255) [not null]
  sequence int [not null]
  createdAt timestamp [not null]
  updatedAt timestamp [not null]
  deletedAt timestamp

  indexes {
    (courseId, sequence) [unique]
    courseId
    deletedAt
  }
}

Table LessonMedia {
  lessonId varchar(36) [pk, ref: > Lesson.id]
  mediaId varchar(36) [pk, ref: > Media.id]
  sequence int [not null]

  indexes {
    (lessonId, sequence) [unique]
    mediaId
  }
}

// ─── Learning paths ──────────────────────────────────────────────────────────

Table LearningPath {
  id varchar(36) [pk]
  userId varchar(36) [not null, ref: > User.id]
  title varchar(255) [not null]
  createdAt timestamp [not null]
  updatedAt timestamp [not null]
  deletedAt timestamp

  indexes {
    deletedAt
  }
}

Table LearningPathCourse {
  learningPathId varchar(36) [pk, ref: > LearningPath.id]
  courseId varchar(36) [pk, ref: > Course.id]
  sequence int [not null]

  indexes {
    (learningPathId, sequence) [unique]
    courseId
  }
}

// ─── Enrollments ─────────────────────────────────────────────────────────────

Table CourseEnrollment {
  id varchar(36) [pk]
  courseId varchar(36) [not null, ref: > Course.id]
  userId varchar(36) [not null, ref: > User.id]
  createdAt timestamp [not null]

  indexes {
    (userId, courseId) [unique]
    courseId
  }
}

Table LearningPathEnrollment {
  id varchar(36) [pk]
  learningPathId varchar(36) [not null, ref: > LearningPath.id]
  userId varchar(36) [not null, ref: > User.id]
  createdAt timestamp [not null]
  completedAt timestamp

  indexes {
    (userId, learningPathId) [unique]
    learningPathId
  }
}

// ─── Progress ────────────────────────────────────────────────────────────────

Table UserMediaProgress {
  id varchar(36) [pk]
  userId varchar(36) [not null, ref: > User.id]
  mediaId varchar(36) [not null, ref: > Media.id]
  progressPercentage int [not null, default: 0, note: "0–100; video advances monotonically; non-video forced to 100 on first call"]
  completedAt timestamp [note: "set when video >= 90% or non-video on first call"]
  createdAt timestamp [not null]
  updatedAt timestamp [not null]

  indexes {
    (userId, mediaId) [unique]
    mediaId
    (userId, completedAt)
  }
}

Table UserLessonProgress {
  userId varchar(36) [not null, ref: > User.id]
  lessonId varchar(36) [not null, ref: > Lesson.id]
  courseId varchar(36) [not null, ref: > Course.id]
  completedAt timestamp [note: "null until the learner explicitly completes the lesson"]

  indexes {
    (userId, lessonId) [unique]
    (userId, courseId)
  }
}

Table UserCourseProgress {
  id varchar(36) [pk]
  userId varchar(36) [not null, ref: > User.id]
  courseId varchar(36) [not null, ref: > Course.id]
  progressPercentage int [not null, default: 0, note: "0–100; completed lessons / total lessons × 100"]
  completedAt timestamp [note: "set when all lessons in the course are completed"]
  createdAt timestamp [not null]
  updatedAt timestamp [not null]

  indexes {
    (userId, courseId) [unique]
  }
}

Table UserCourseLearningPathProgress {
  userId varchar(36) [not null, ref: > User.id]
  learningPathId varchar(36) [not null, ref: > LearningPath.id]
  courseId varchar(36) [not null, ref: > Course.id]
  completedAt timestamp [note: "null until the learner explicitly credits the completed course"]

  indexes {
    (userId, learningPathId, courseId) [unique]
    (userId, learningPathId)
  }
}

Table UserLearningPathProgress {
  id varchar(36) [pk]
  userId varchar(36) [not null, ref: > User.id]
  learningPathId varchar(36) [not null, ref: > LearningPath.id]
  progressPercentage int [not null, default: 0, note: "0–100; credited courses / total courses × 100"]
  completedAt timestamp [note: "set when every course in the learning path is credited"]
  createdAt timestamp [not null]
  updatedAt timestamp [not null]

  indexes {
    (userId, learningPathId) [unique]
  }
}

// ─── Engagement ──────────────────────────────────────────────────────────────

Table Bookmark {
  id varchar(36) [pk]
  userId varchar(36) [not null, ref: > User.id]
  contentId varchar(36) [not null]
  contentType varchar(20) [not null, note: 'MEDIA | COURSE | LEARNING_PATH']
  createdAt timestamp [not null]

  indexes {
    (userId, contentId, contentType) [unique]
    (userId, createdAt, id)
    (userId, contentType, createdAt, id)
  }
}

Table Badge {
  id varchar(36) [pk]
  mediaId varchar(36) [not null, ref: > Media.id]
  badgeAssetId varchar(36) [not null, ref: > Asset.id]
  title varchar(100) [not null]
  createdAt timestamp [not null]
  updatedAt timestamp [not null]
  deletedAt timestamp

  indexes {
    deletedAt
  }
}

Table Comment {
  id varchar(36) [pk]
  userId varchar(36) [not null, ref: > User.id]
  contentId varchar(36) [not null]
  contentType varchar(25) [not null]
  parentCommentId varchar(36) [ref: > Comment.id]
  text varchar(256) [not null]
  createdAt timestamp [not null]
  updatedAt timestamp [not null]
  deletedAt timestamp

  indexes {
    (contentId, contentType, deletedAt, createdAt)
    (parentCommentId, deletedAt, createdAt)
    userId
    deletedAt
  }
}

// ─── User activities (follow, reactions) ─────────────────────────────────────

Table Follow {
  followerId varchar(36) [not null, ref: > User.id]
  followeeId varchar(36) [not null, ref: > User.id]
  createdAt timestamp [not null]

  indexes {
    (followerId, followeeId) [pk]
    (followeeId, createdAt)
    (followerId, createdAt)
  }

  checks {
    `followerId <> followeeId` [name: 'chk_follow_no_self']
  }
}

Table ContentReaction {
  id varchar(36) [pk]
  userId varchar(36) [not null, ref: > User.id]
  contentId varchar(36) [not null]
  contentType varchar(20) [not null]
  type varchar(20) [not null]
  createdAt timestamp [not null]

  indexes {
    (userId, contentId, contentType, type) [unique]
    userId
    (userId, createdAt)
  }
}

// ─── Moderation (review workflow + audit) ────────────────────────────────────

Table ReviewLog {
  id varchar(36) [pk]
  targetType varchar(25) [not null]   // MEDIA | COURSE
  targetId varchar(36) [not null]     // no FK — resolved via domain port, not DB
  reviewerId varchar(36) [not null, ref: > User.id]
  decision varchar(25) [not null]     // SUBMITTED | APPROVED | REJECTED
  fromStatus varchar(25) [not null]
  toStatus varchar(25) [not null]
  reason varchar(2000)                // required when decision = REJECTED
  createdAt timestamp [not null]

  indexes {
    (targetType, targetId, createdAt)  // full history of one item
    (decision, createdAt)              // moderator activity feed
    reviewerId
  }
}

// ─── Table groups (visual layout on dbdiagram.io) ──────────────────────────────

TableGroup master_data {
  LearningGoal
  SubLearningGoal
  Tag
  LearningSubjectGroup
  EducationLevel
  GradeLevel
}

TableGroup asset_and_media {
  Asset
  Media
  MediaTag
  MediaSubLearningGoal
  VideoMedia
  ArticleMedia
  DocumentMedia
  EbookMedia
}

TableGroup course_structure {
  Course
  CourseGradeLevel
  CourseLearningSubjectGroup
  Lesson
  LessonMedia
}

TableGroup learning_paths {
  LearningPath
  LearningPathCourse
}

TableGroup enrollments {
  CourseEnrollment
  LearningPathEnrollment
}

TableGroup progress {
  UserMediaProgress
  UserLessonProgress
  UserCourseProgress
  UserCourseLearningPathProgress
  UserLearningPathProgress
}

TableGroup engagement {
  Bookmark
  Badge
  Comment
  Follow
  ContentReaction
}

TableGroup moderation {
  ReviewLog
}
