# Forms Admin API v2

Documentation for the API v2 endpoints for forms admin.

## Actions

- [Get draft form document](#get-draft-form-document) - `GET /api/v2/forms/:form_id/draft`
- [Get live form document](#get-live-form-document) - `GET /api/v2/forms/:form_id/live`
- [Get archived form document](#get-archived-form-document) - `GET /api/v2/forms/:form_id/archived`
- [Get form group](#get-form-group) - `GET /api/v2/forms/:form_id/group`

## Data types

- [FormDocument](#formdocument)
- [Step](#step)
- [Data](#data)
- [AnswerSettings](#answersettings)
- [SelectionOption](#selectionoption)
- [NoneOfTheAboveQuestion](#noneoftheabovequestion)
- [RoutingCondition](#routingcondition)
- [Group](#group)
- [Organisation](#organisation)
- [User](#user)

## Get draft form document

Returns the draft form document for a form.

### Request syntax

```http
GET /api/v2/forms/{form_id}/draft?language={language}
```

### URI request parameters


| Name       | Required | Type   | Description                                                              |
| ---------- | -------- | ------ | ------------------------------------------------------------------------ |
| `form_id`  | Yes      | String | The ID of the form.                                                      |
| `language` | No       | String | The document language. Valid values are `en` and `cy`. Defaults to `en`. |


### Request body

The request does not have a body.

### Response syntax

```json
{
  "form_id": "123",
  "name": "Apply for a thing",
  "available_languages": ["en", "cy"],
  "language": "en",
  "form_slug": "apply-for-a-thing",
  "created_at": "2026-05-14T08:30:00.000Z",
  "updated_at": "2026-05-14T08:30:00.000Z",
  "first_made_live_at": "2026-05-01T09:00:00.000Z",
  "start_page": "RxnBENyD",
  "payment_url": null,
  "support_url": null,
  "support_email": "support@example.gov.uk",
  "support_phone": null,
  "support_url_text": null,
  "privacy_policy_url": "https://www.gov.uk/privacy",
  "submission_type": "email",
  "submission_format": ["csv"],
  "submission_email": "submissions@example.gov.uk",
  "declaration_text": null,
  "declaration_markdown": null,
  "what_happens_next_markdown": null,
  "send_daily_submission_batch": false,
  "send_weekly_submission_batch": false,
  "steps": [
    {
      "id": "RxnBENyD",
      "position": 1,
      "next_step_id": "8AyfsK2Q",
      "type": "question",
      "data": {
        "question_text": "What is your name?",
        "hint_text": null,
        "answer_type": "text",
        "is_optional": false,
        "answer_settings": {
          "input_type": "single_line"
        },
        "page_heading": null,
        "guidance_markdown": null,
        "is_repeatable": false
      },
      "routing_conditions": []
    }
  ]
}
```

### Response elements


| Name           | Type                          | Description                            |
| -------------- | ----------------------------- | -------------------------------------- |
| `FormDocument` | [FormDocument](#formdocument) | The current draft version of the form. |


### Errors


| Error                   | HTTP status code | Description                                                                                                 |
| ----------------------- | ---------------- | ----------------------------------------------------------------------------------------------------------- |
| `not_found`             | `404`            | The form does not exist, or a draft form document does not exist for the supplied `form_id` and `language`. |
| `internal_server_error` | `500`            | An unhandled server error occurred.                                                                         |


## Get live form document

Returns the live form document for a form.

### Request syntax

```http
GET /api/v2/forms/{form_id}/live?language={language}
```

### URI request parameters


| Name       | Required | Type   | Description                                                              |
| ---------- | -------- | ------ | ------------------------------------------------------------------------ |
| `form_id`  | Yes      | String | The ID of the form.                                                      |
| `language` | No       | String | The document language. Valid values are `en` and `cy`. Defaults to `en`. |


### Request body

The request does not have a body.

### Response syntax

```json
{
  "name": "Apply for a parking permit",
  "form_id": "123",
  "language": "en",
  "form_slug": "apply-for-a-parking-permit",
  "created_at": "2026-04-01T10:51:32.791519Z",
  "creator_id": 17,
  "start_page": "RxnBENyD",
  "updated_at": "2026-05-14T11:49:13.862506Z",
  "live_at": "2026-05-14T11:50:02.123456Z",
  "payment_url": null,
  "support_url": "https://www.example.gov.uk/parking-permits/contact",
  "support_email": "parking.permits@example.gov.uk",
  "support_phone": null,
  "s3_bucket_name": null,
  "submission_type": "email",
  "declaration_text": null,
  "s3_bucket_region": null,
  "submission_email": "parking.permits@example.gov.uk",
  "support_url_text": "Contact the parking permits team",
  "submission_format": ["csv", "json"],
  "first_made_live_at": "2026-04-10T09:15:11.453375Z",
  "privacy_policy_url": "https://www.example.gov.uk/privacy",
  "available_languages": ["en", "cy"],
  "declaration_markdown": "I confirm that the information I have provided is correct.",
  "s3_bucket_aws_account_id": null,
  "what_happens_next_markdown": "We will review your application and email you within 5 working days.",
  "send_daily_submission_batch": false,
  "send_weekly_submission_batch": false,
  "steps": [
    {
      "id": "RxnBENyD",
      "data": {
        "hint_text": null,
        "answer_type": "selection",
        "is_optional": false,
        "page_heading": null,
        "is_repeatable": false,
        "question_text": "What type of parking permit do you need?",
        "answer_settings": {
          "only_one_option": "true",
          "selection_options": [
            {
              "name": "Resident permit",
              "value": "Resident permit"
            },
            {
              "name": "Business permit",
              "value": "Business permit"
            }
          ]
        },
        "guidance_markdown": null
      },
      "type": "question",
      "position": 1,
      "next_step_id": "8AyfsK2Q",
      "routing_conditions": [
        {
          "id": 42,
          "created_at": "2026-05-14T11:49:05.594292Z",
          "updated_at": "2026-05-14T11:49:05.594292Z",
          "skip_to_end": false,
          "answer_value": "Business permit",
          "goto_page_id": "QV2JQUtT",
          "check_page_id": "RxnBENyD",
          "routing_page_id": "RxnBENyD",
          "exit_page_heading": null,
          "validation_errors": {},
          "exit_page_markdown": null
        }
      ]
    },
    {
      "id": "8AyfsK2Q",
      "data": {
        "hint_text": "For example, AB12 CDE",
        "answer_type": "text",
        "is_optional": false,
        "page_heading": null,
        "is_repeatable": true,
        "question_text": "What is the vehicle registration number?",
        "answer_settings": {
          "input_type": "single_line"
        },
        "guidance_markdown": null
      },
      "type": "question",
      "position": 2,
      "next_step_id": "k7Pq9LmN",
      "routing_conditions": []
    },
    {
      "id": "QV2JQUtT",
      "data": {
        "hint_text": null,
        "answer_type": "organisation_name",
        "is_optional": false,
        "page_heading": "Business details",
        "is_repeatable": false,
        "question_text": "What is the business name?",
        "answer_settings": {},
        "guidance_markdown": "Tell us the legal name of the business applying for the permit."
      },
      "type": "question",
      "position": 3,
      "next_step_id": "k7Pq9LmN",
      "routing_conditions": []
    },
    {
      "id": "k7Pq9LmN",
      "data": {
        "hint_text": "We will use this to send updates about the application.",
        "answer_type": "email",
        "is_optional": false,
        "page_heading": null,
        "is_repeatable": false,
        "question_text": "What is your email address?",
        "answer_settings": {},
        "guidance_markdown": null
      },
      "type": "question",
      "position": 4,
      "next_step_id": null,
      "routing_conditions": []
    }
  ]
}
```

### Response elements


| Name           | Type                          | Description                           |
| -------------- | ----------------------------- | ------------------------------------- |
| `FormDocument` | [FormDocument](#formdocument) | The current live version of the form. |


### Errors


| Error                   | HTTP status code | Description                                                                                                |
| ----------------------- | ---------------- | ---------------------------------------------------------------------------------------------------------- |
| `not_found`             | `404`            | The form does not exist, or a live form document does not exist for the supplied `form_id` and `language`. |
| `internal_server_error` | `500`            | An unhandled server error occurred.                                                                        |


## Get archived form document

Returns the archived form document for a form.

### Request syntax

```http
GET /api/v2/forms/{form_id}/archived?language={language}
```

### URI request parameters


| Name       | Required | Type   | Description                                                              |
| ---------- | -------- | ------ | ------------------------------------------------------------------------ |
| `form_id`  | Yes      | String | The ID of the form.                                                      |
| `language` | No       | String | The document language. Valid values are `en` and `cy`. Defaults to `en`. |


### Request body

The request does not have a body.

### Response syntax

```json
{
  "name": "Apply for a parking permit",
  "form_id": "123",
  "language": "en",
  "form_slug": "apply-for-a-parking-permit",
  "created_at": "2026-04-01T10:51:32.791519Z",
  "creator_id": 17,
  "start_page": "RxnBENyD",
  "updated_at": "2026-04-30T14:22:09.018342Z",
  "live_at": "2026-04-30T14:25:00.000000Z",
  "payment_url": null,
  "support_url": "https://www.example.gov.uk/parking-permits/contact",
  "support_email": "parking.permits@example.gov.uk",
  "support_phone": null,
  "s3_bucket_name": null,
  "submission_type": "email",
  "declaration_text": null,
  "s3_bucket_region": null,
  "submission_email": "parking.permits@example.gov.uk",
  "support_url_text": "Contact the parking permits team",
  "submission_format": ["csv"],
  "first_made_live_at": "2026-04-10T09:15:11.453375Z",
  "privacy_policy_url": "https://www.example.gov.uk/privacy",
  "available_languages": ["en"],
  "declaration_markdown": "I confirm that the information I have provided is correct.",
  "s3_bucket_aws_account_id": null,
  "what_happens_next_markdown": "We will contact you when your permit has been approved.",
  "send_daily_submission_batch": false,
  "send_weekly_submission_batch": false,
  "steps": [
    {
      "id": "RxnBENyD",
      "data": {
        "hint_text": null,
        "answer_type": "selection",
        "is_optional": false,
        "page_heading": null,
        "is_repeatable": false,
        "question_text": "What type of parking permit are you applying for?",
        "answer_settings": {
          "only_one_option": "true",
          "selection_options": [
            {
              "name": "Resident permit",
              "value": "Resident permit"
            },
            {
              "name": "Visitor permit",
              "value": "Visitor permit"
            }
          ]
        },
        "guidance_markdown": null
      },
      "type": "question",
      "position": 1,
      "next_step_id": "8AyfsK2Q",
      "routing_conditions": []
    },
    {
      "id": "8AyfsK2Q",
      "data": {
        "hint_text": "You can find this on the vehicle number plate.",
        "answer_type": "text",
        "is_optional": false,
        "page_heading": null,
        "is_repeatable": false,
        "question_text": "What is the vehicle registration number?",
        "answer_settings": {
          "input_type": "single_line"
        },
        "guidance_markdown": null
      },
      "type": "question",
      "position": 2,
      "next_step_id": "QV2JQUtT",
      "routing_conditions": []
    },
    {
      "id": "QV2JQUtT",
      "data": {
        "hint_text": "Use the address where the permit will be used.",
        "answer_type": "address",
        "is_optional": false,
        "page_heading": "Applicant details",
        "is_repeatable": false,
        "question_text": "What is your address?",
        "answer_settings": {
          "input_type": {
            "uk_address": "true",
            "international_address": "false"
          }
        },
        "guidance_markdown": null
      },
      "type": "question",
      "position": 3,
      "next_step_id": null,
      "routing_conditions": []
    }
  ]
}
```

### Response elements


| Name           | Type                          | Description                            |
| -------------- | ----------------------------- | -------------------------------------- |
| `FormDocument` | [FormDocument](#formdocument) | The last archived version of the form. |


### Errors


| Error                   | HTTP status code | Description                                                                                                     |
| ----------------------- | ---------------- | --------------------------------------------------------------------------------------------------------------- |
| `not_found`             | `404`            | The form does not exist, or an archived form document does not exist for the supplied `form_id` and `language`. |
| `internal_server_error` | `500`            | An unhandled server error occurred.                                                                             |


## Get form group

Returns the group and organisation details for a form.

### Request syntax

```http
GET /api/v2/forms/{form_id}/group
```

### URI request parameters


| Name      | Required | Type   | Description         |
| --------- | -------- | ------ | ------------------- |
| `form_id` | Yes      | String | The ID of the form. |


### Request body

The request does not have a body.

### Response syntax

```json
{
  "external_id": "group-external-id",
  "name": "Service team",
  "group_admin_users": [
    {
      "name": "Group Admin",
      "email": "group.admin@example.gov.uk"
    }
  ],
  "organisation": {
    "id": 1,
    "name": "Government Digital Service",
    "organisation_admin_users": [
      {
        "name": "Organisation Admin",
        "email": "organisation.admin@example.gov.uk"
      }
    ]
  }
}
```

### Response elements


| Name    | Type            | Description                                                             |
| ------- | --------------- | ----------------------------------------------------------------------- |
| `Group` | [Group](#group) | The form's group, including group admin users and organisation details. |


### Errors


| Error                   | HTTP status code | Description                         |
| ----------------------- | ---------------- | ----------------------------------- |
| `not_found`             | `404`            | The form does not exist.            |
| `internal_server_error` | `500`            | An unhandled server error occurred. |


## FormDocument

A form document describes the configuration of a form.

### Syntax

```json
{
  "form_id": string,
  "name": string,
  "available_languages": [string],
  "language": string,
  "form_slug": string,
  "created_at": timestamp,
  "creator_id": number,
  "updated_at": timestamp,
  "first_made_live_at": timestamp,
  "live_at": timestamp,
  "start_page": string,
  "payment_url": string,
  "support_url": string,
  "support_email": string,
  "support_phone": string,
  "support_url_text": string,
  "privacy_policy_url": string,
  "s3_bucket_name": string,
  "s3_bucket_region": string,
  "s3_bucket_aws_account_id": string,
  "submission_type": string,
  "submission_format": [string],
  "submission_email": string,
  "declaration_text": string,
  "declaration_markdown": string,
  "what_happens_next_markdown": string,
  "send_daily_submission_batch": boolean,
  "send_weekly_submission_batch": boolean,
  "steps": [Step]
}
```

### Members


| Name                           | Type                   | Description                                                         |
| ------------------------------ | ---------------------- | ------------------------------------------------------------------- |
| `form_id`                      | String                 | The ID of the form.                                                 |
| `name`                         | String                 | The form name in the requested language.                            |
| `available_languages`          | Array of strings       | Languages available for the form. Current values are `en` and `cy`. |
| `language`                     | String                 | The language of this document. Current values are `en` and `cy`.    |
| `form_slug`                    | String                 | The form slug.                                                      |
| `created_at`                   | Timestamp              | When the form was created.                                          |
| `creator_id`                   | Number                 | The ID of the user who created the form.                            |
| `updated_at`                   | Timestamp              | When the form was last updated.                                     |
| `first_made_live_at`           | Timestamp              | When the form was first made live.                                  |
| `live_at`                      | Timestamp              | When this document was generated for a live version.                |
| `start_page`                   | String                 | The step ID of the first step.                                      |
| `payment_url`                  | String                 | A GOV.UK Pay payment URL.                                           |
| `support_url`                  | String                 | Support URL.                                                        |
| `support_email`                | String                 | Support email address.                                              |
| `support_phone`                | String                 | Support phone number.                                               |
| `support_url_text`             | String                 | Link text for the support URL.                                      |
| `privacy_policy_url`           | String                 | Privacy policy URL.                                                 |
| `s3_bucket_name`               | String                 | S3 bucket name for S3 submissions.                                  |
| `s3_bucket_region`             | String                 | S3 bucket region for S3 submissions.                                |
| `s3_bucket_aws_account_id`     | String                 | AWS account ID for S3 submissions.                                  |
| `submission_type`              | String                 | Submission destination type. Valid values are `email` or `s3`.      |
| `submission_format`            | Array of strings       | Submission attachment formats, Valid values are `csv` or `json`.    |
| `submission_email`             | String                 | Email address to send email submissions.                            |
| `declaration_text`             | String                 | Plain text declaration content.                                     |
| `declaration_markdown`         | String                 | Markdown declaration content.                                       |
| `what_happens_next_markdown`   | String                 | Markdown content shown after submission.                            |
| `send_daily_submission_batch`  | Boolean                | Whether daily submission CSV batches are enabled.                   |
| `send_weekly_submission_batch` | Boolean                | Whether weekly submission CSV batches are enabled.                  |
| `steps`                        | Array of [Step](#step) | Steps in the form.                                                  |


String and timestamp members can be `null` when the form has no stored value for that field.

## Step

A page in a form document.

### Syntax

```json
{
  "id": string,
  "position": number,
  "next_step_id": string,
  "type": string,
  "data": Data,
  "routing_conditions": [RoutingCondition]
}
```

### Members


| Name                 | Type                                           | Description                                                                        |
| -------------------- | ---------------------------------------------- | ---------------------------------------------------------------------------------- |
| `id`                 | String                                         | The step ID.                                                                       |
| `position`           | Number                                         | The step position in the form.                                                     |
| `next_step_id`       | String                                         | The ID of the next step, or `null` when this is the final page.                    |
| `type`               | String                                         | The step type. Current value is `question`.                                        |
| `data`               | [Data](#data)                                  | Question content and answer configuration.                                         |
| `routing_conditions` | Array of [RoutingCondition](#routingcondition) | Routing rules that start from this page. Empty when the page has no routing rules. |


## Data

Question content and settings for a step.

### Syntax

```json
{
  "question_text": string,
  "hint_text": string,
  "answer_type": string,
  "is_optional": boolean,
  "answer_settings": AnswerSettings,
  "page_heading": string,
  "guidance_markdown": string,
  "is_repeatable": boolean
}
```

### Members


| Name                | Type                              | Description                                                                                                                                                                          |
| ------------------- | --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `question_text`     | String                            | The question text in the requested language.                                                                                                                                         |
| `hint_text`         | String                            | Optional hint text in the requested language.                                                                                                                                        |
| `answer_type`       | String                            | The answer type. Current values are `name`, `organisation_name`, `email`, `phone_number`, `national_insurance_number`, `address`, `date`, `selection`, `number`, `text`, and `file`. |
| `is_optional`       | Boolean                           | Whether the question is optional.                                                                                                                                                    |
| `answer_settings`   | [AnswerSettings](#answersettings) | Answer settings for the answer type. Can be an empty object.                                                                                                                         |
| `page_heading`      | String                            | Optional guidance page heading in the requested language.                                                                                                                            |
| `guidance_markdown` | String                            | Optional guidance markdown in the requested language.                                                                                                                                |
| `is_repeatable`     | Boolean                           | Whether the answer can be repeated with "add another".                                                                                                                               |


String members can be `null` when no value is stored.

## AnswerSettings

Settings for a question's answer type. The object shape depends on `Data.answer_type`.

### Text answer settings

Used when `answer_type` is `text`.

```json
{
  "input_type": string
}
```


| Name         | Type   | Description                                     |
| ------------ | ------ | ----------------------------------------------- |
| `input_type` | String | Valid values are `single_line` and `long_text`. |


### Date answer settings

Used when `answer_type` is `date`.

```json
{
  "input_type": string
}
```


| Name         | Type   | Description                                        |
| ------------ | ------ | -------------------------------------------------- |
| `input_type` | String | Valid values are `date_of_birth` and `other_date`. |


### Address answer settings

Used when `answer_type` is `address`.

```json
{
  "input_type": {
    "uk_address": string,
    "international_address": string
  }
}
```


| Name                               | Type   | Description                                                                        |
| ---------------------------------- | ------ | ---------------------------------------------------------------------------------- |
| `input_type.uk_address`            | String | Whether UK addresses are accepted. Valid values are `true` and `false`.            |
| `input_type.international_address` | String | Whether international addresses are accepted. Valid values are `true` and `false`. |


### Name answer settings

Used when `answer_type` is `name`.

```json
{
  "input_type": string,
  "title_needed": string
}
```


| Name           | Type              | Description                                                                                                                              |
| -------------- | ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `input_type`   | String            | Valid values are `full_name`, `first_and_last_name`, and `first_middle_and_last_name`.                                                   |
| `title_needed` | String or Boolean | Whether the name answer asks for a title. Current UI writes `true` or `false` strings; stored documents can also contain boolean values. |


### Selection answer settings

Used when `answer_type` is `selection`.

```json
{
  "only_one_option": string,
  "selection_options": [SelectionOption],
  "none_of_the_above_question": NoneOfTheAboveQuestion
}
```


| Name                         | Type                                              | Description                                                                                  |
| ---------------------------- | ------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `only_one_option`            | String                                            | Whether a user can choose only one option. Valid values are `true` and `false`.              |
| `selection_options`          | Array of [SelectionOption](#selectionoption)      | Available selection options.                                                                 |
| `none_of_the_above_question` | [NoneOfTheAboveQuestion](#noneoftheabovequestion) | Follow-up question shown when "None of the above" is selected. Present only when configured. |


### Empty answer settings

Some answer types have no extra settings and return an empty object:

```json
{}
```

This applies to `organisation_name`, `email`, `phone_number`, `national_insurance_number`, `number`, and `file`.

## SelectionOption

An option for a selection question.

For English form documents, `name` and `value` are usually the same because the stored value is created from the option text. For translated form documents, `name` is the translated display text and `value` remains the stored value from the original English option. For example, a Welsh document can return `{ "name": "Trwydded preswylydd", "value": "Resident permit" }`.

### Syntax

```json
{
  "name": string,
  "value": string
}
```

### Members


| Name    | Type   | Description                                            |
| ------- | ------ | ------------------------------------------------------ |
| `name`  | String | Display text for the option in the requested language. |
| `value` | String | Stored value for the option, used in submitted answers and routing conditions. |


## NoneOfTheAboveQuestion

Follow-up question shown when a user chooses "None of the above" on a selection question.

### Syntax

```json
{
  "question_text": string,
  "is_optional": string
}
```

### Members


| Name            | Type   | Description                                                                      |
| --------------- | ------ | -------------------------------------------------------------------------------- |
| `question_text` | String | Follow-up question text in the requested language.                               |
| `is_optional`   | String | Whether the follow-up question is optional. Valid values are `true` and `false`. |


## RoutingCondition

A routing rule for a step.

### Syntax

```json
{
  "id": number,
  "routing_page_id": string,
  "check_page_id": string,
  "goto_page_id": string,
  "answer_value": string,
  "skip_to_end": boolean,
  "exit_page_heading": string,
  "exit_page_markdown": string,
  "validation_errors": {},
  "created_at": timestamp,
  "updated_at": timestamp
}
```

### Members


| Name                 | Type      | Description                                                                                         |
| -------------------- | --------- | --------------------------------------------------------------------------------------------------- |
| `id`                 | Number    | The ID of the routing condition.                                                                    |
| `routing_page_id`    | String    | External ID of the page where the route starts.                                                     |
| `check_page_id`      | String    | External ID of the page whose answer is checked.                                                    |
| `goto_page_id`       | String    | External ID of the page to skip to, or `null` for exit routes and routes that skip to the end.      |
| `answer_value`       | String    | Answer value that triggers the route. Can be `null` for routes that do not check a specific answer. |
| `skip_to_end`        | Boolean   | Whether the route skips to the end of the form.                                                     |
| `exit_page_heading`  | String    | Heading for an exit page route.                                                                     |
| `exit_page_markdown` | String    | Markdown body for an exit page route.                                                               |
| `validation_errors`  | Object    | Validation errors for the route. Empty when no errors are stored.                                   |
| `created_at`         | Timestamp | When the routing condition was created.                                                             |
| `updated_at`         | Timestamp | When the routing condition was last updated.                                                        |


## Group

Group details returned by the get form group action.

### Syntax

```json
{
  "external_id": string,
  "name": string,
  "group_admin_users": [User],
  "organisation": Organisation
}
```

### Members


| Name                | Type                          | Description                                    |
| ------------------- | ----------------------------- | ---------------------------------------------- |
| `external_id`       | String                        | Public external ID of the group.               |
| `name`              | String                        | Group name.                                    |
| `group_admin_users` | Array of [User](#user)        | Users with the group admin role. Can be empty. |
| `organisation`      | [Organisation](#organisation) | Organisation that owns the group.              |


## Organisation

Organisation details returned inside `Group`.

### Syntax

```json
{
  "id": number,
  "name": string,
  "organisation_admin_users": [User]
}
```

### Members


| Name                       | Type                   | Description                                           |
| -------------------------- | ---------------------- | ----------------------------------------------------- |
| `id`                       | Number                 | ID of the organisation.                               |
| `name`                     | String                 | Organisation name.                                    |
| `organisation_admin_users` | Array of [User](#user) | Users with the organisation admin role. Can be empty. |


## User

A user summary returned in group and organisation admin lists.

### Syntax

```json
{
  "name": string,
  "email": string
}
```

### Members


| Name    | Type   | Description         |
| ------- | ------ | ------------------- |
| `name`  | String | Name of the user.   |
| `email` | String | User email address. |


