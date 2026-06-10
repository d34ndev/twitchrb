# Changelog

All notable changes to `twitchrb` are documented in this file.

Published release notes were sourced from GitHub releases where available. Older tag-only versions and the current unreleased work were reconstructed from local git history.

## [Unreleased]

### Fixed
- Fixed a `NoMethodError` crash when API responses have non-JSON bodies, such as `stream_schedule.icalendar` (which was completely broken) and HTML error pages from proxies.
- Fixed `users.retrieve` and `games.retrieve` returning `nil` when a plural lookup (`ids`, `usernames`, `names`) matched exactly one item; plural lookups now always return a `Collection`. Singular lookups with no match now return `nil` instead of an empty object.
- Fixed `oauth.revoke` always returning `true`; it now returns `false` when revocation fails, matching `validate`, `create`, and `refresh`.
- Fixed `blocked_terms.create` returning a `BannedUser` instead of a `BlockedTerm`.
- Fixed `suspicious_users.delete` crashing on 204 No Content responses; it now returns `true`.
- Fixed query string values not being escaped in request paths. Notably, `users.update_color` silently dropped hex colors like `#9146FF`.
- Errors are now raised for any 4xx/5xx response; previously 422, 502, and 504 slipped through unraised.
- `Collection#total` now reports the `total` field from the API for paginated endpoints instead of the page size, and responses without a `data` key return an empty collection instead of raising.
- Removed a leftover debug `puts` in `users.get_color`.
- Error messages for unmapped statuses no longer duplicate the Twitch message.

### Changed
- The `auto_retry_rate_limit` client option (default `true`) now works: requests that hit a 429 wait until the rate limit window resets and retry once. Previously the option was accepted but ignored.
- All API errors now inherit from `Twitch::Error`, so they can be rescued with a single base class.
- `eventsub_subscriptions.create` now goes through the shared request helpers, gaining request path validation and rate limit auto-retry.

### Added
- `users.get_color` accepts an array for `user_ids`, in line with other multi-id endpoints. Comma-separated strings still work.

## [1.10.0] - 2026-05-16

### Added
- Added custom power-up API support.
- Added shared chat announcement support.
- Added shared chat session support.
- Added suspicious user moderation APIs.
- Added VOD clip creation and downloads.
- Added pinned chat message support.

### Changed
- Replaced hype train events with the status API.
- Improved EventSub subscription conflict handling.

### Fixed
- Fixed SSRF via protocol-relative request paths.

## [1.9.1] - 2025-12-06

### Fixed
- Permissions fix.

## [1.9.0] - 2025-12-05

### Changed
- Tag-only release with no published release notes or recorded user-facing changes beyond the version bump.

## [1.8.1] - 2025-12-05

### Added
- Added support for Start Commercial.

### Changed
- Imported `Enumerable` into collections.

## [1.8.0] - 2025-12-01

### Added
- Added support for Get Stream Key.

## [1.7.0] - 2025-10-20

### Added
- Added support for Get Authorization By User.

## [1.6.0] - 2025-09-13

### Fixed
- Fixed issues in the error generator.

## [1.5.0] - 2025-09-12

### Added
- Added an explicit `ostruct` dependency.

### Changed
- Updated Faraday.

## [1.4.0] - 2024-08-02

### Added
- Added a new error generator.

### Changed
- Required `ostruct` globally.
- Refreshed CI and dependency configuration.

## [1.3.0] - 2024-06-28

### Added
- Added Warn Chat User API support.
- Added `each`, `first`, and `last` on collections.

## [1.2.6] - 2024-05-27

### Fixed
- Returned `false` when token validation fails.

### Changed
- Minor README updates.

## [1.2.5] - 2024-03-17

### Added
- Added Unban Requests API support.
- Added Get User Emotes API support.

## [1.2.4] - 2024-01-31

### Fixed
- Fixed users/games lookups so `ids`, `usernames`, and `names` return collections consistently.

## [1.2.3] - 2024-01-27

### Added
- Added send chat messages support.

## [1.2.2] - 2024-01-09

### Added
- Added `moderators.channels`.

## [1.2.1] - 2024-01-02

### Fixed
- Fixed custom reward redemption updates.
- Corrected documentation headings and repository metadata.

### Changed
- Added Ruby 3.3 to CI coverage.

## [1.2.0] - 2023-10-29

### Changed
- Renamed Users `get_by_id` to `retrieve`.
- Renamed Users `get_by_username` to `retrieve`.
- Expanded Users `retrieve` to accept `id`, `ids`, `name`, and `names`.
- Renamed Channels `get` to `retrieve`.

### Added
- Added Videos `retrieve`.
- Added Games `retrieve` with support for `id`, `ids`, `name`, and `names`.

## [1.1.0] - 2023-02-21

### Added
- Added support for Get Followed Channels.
- Added support for Get Channel Followers.

### Deprecated
- Deprecated `user.follows`.
- Deprecated `user.following?` ahead of the Twitch API removal on August 3, 2023.

## [1.0.4] - 2023-01-22

### Changed
- Set the default User-Agent.

## [1.0.3] - 2023-01-22

### Added
- Added support for Shoutouts.

## [1.0.2] - 2022-10-02

### Added
- Added Chatters support.

### Fixed
- Fixed Charity Campaigns handling.

## [1.0.1] - 2022-08-26

### Added
- Added support for the Charity Campaigns API.

## [1.0.0] - 2022-07-18

### Changed
- Removed Client Secret as a required client value; only Client ID and Access Token are required.

### Added
- Added chat announcements.
- Added raids.
- Added chat message deletion.
- Added user chat colours.
- Added moderator management.
- Added VIP management.
- Added send whisper support.
- Added AutoMod status.
- Added AutoMod settings get/update support.
- Added ban/unban user support.
- Added blocked terms management.

## [0.2.6] - 2022-04-26

### Changed
- Removed thumbnail handling that was no longer needed.

## [0.2.5] - 2022-04-10

### Added
- Added channel follow count support.
- Added subscriber counts to channels.
- Expanded test coverage.

### Changed
- Upgraded to Faraday 2.
- Improved project documentation.

## [0.2.4] - 2021-12-31

### Fixed
- Fixed handling for resources without a thumbnail URL.

## [0.2.3] - 2021-12-31

### Added
- Added `require "twitchrb"` so `require "twitch"` is no longer necessary.
- Added generated large thumbnail and animated image URLs.

### Changed
- Improved channel return behavior.
- Added client secret support in the client flow.

## [0.2.2] - 2021-12-12

### Added
- Added `retrieve` to clips.

## [0.2.1] - 2021-10-02

### Changed
- Removed the older subscriber counting approach in favor of Twitch's newer totals/points behavior.
- Removed Travis CI configuration.

## [0.2.0] - 2021-09-26

### Added
- Expanded the gem to focus on the Twitch Helix API.
- Added badges, emotes, channels, channel editors, games, follows, blocks, videos, clips, EventSub subscriptions, banned events, banned users, moderators, moderator events, polls, predictions, stream schedule segments, search, streams, stream markers, subscriptions, tags, custom rewards, redemptions, goals, and hype train event support.
- Added model-based resource objects and improved error reporting.

### Changed
- Replaced HTTParty with Faraday.
- Simplified collection handling by always reading from `data`.

## [0.1.1] - 2021-06-20

### Added
- Early tagged release of the Helix client.
