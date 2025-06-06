/**
 * Copyright 2022-2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

resource "github_branch_protection" "default" {
  for_each      = var.repo_list
  repository_id = each.value.node_id
  pattern       = each.value.default_branch

  required_pull_request_reviews {
    required_approving_review_count = 1
    require_code_owner_reviews      = true
    pull_request_bypassers = setunion(
      lookup(var.repos_map[each.key], "admin_groups", []),
      formatlist("/%s", lookup(var.repos_map[each.key], "admins", []))
    )
  }

  required_status_checks {
    strict = true
    contexts = setunion([
      "cla/google",
      "${substr(each.key, 0, 50)}-int-trigger (cloud-foundation-cicd)",
      "lint",
      "conventionalcommits.org"
    ], lookup(var.repos_map[each.key], "add_checks", []))
  }

  enforce_admins = false

  restrict_pushes {
    push_allowances = setunion(
      lookup(var.repos_map[each.key], "admin_groups", []),
      formatlist("/%s", setunion(lookup(var.repos_map[each.key], "admins", []), lookup(var.repos_map[each.key], "maintainers", []))),
      formatlist("${var.repos_map[each.key].org}/%s", lookup(var.repos_map[each.key], "groups", []))
    )
    blocks_creations = false
  }
}
