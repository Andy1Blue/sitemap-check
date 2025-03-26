# Sitemap Checker GitHub Action

A GitHub Action to check links in sitemaps and report results to Slack.

## Usage

This GitHub Action checks all URLs listed in a sitemap, validates their HTTP status, and sends a report to a Slack channel.

### Inputs

This action requires the following inputs:

- **sitemap_url**: The URL of the sitemap to check. The placeholder `{locale}` can be used to dynamically insert locale values.  
  Example: `https://www.example.com/{locale}/sitemap.xml`
  
- **exclude**: A comma-separated list of domains or paths to exclude from the check.  
  Example: `microsoft.com,a.storyblok.com,_next,popages.com,youtube,facebook,instagram,object`
  
- **slack_channel**: The Slack channel where the results will be sent.  
  Example: `#my-channel`
  
- **slack_token**: The Slack bot token used to send the messages to the Slack channel. This should be set in your repository secrets.  
  Example: `${{ secrets.SLACK_TOKEN }}`

### Example Workflow

Below is an example of a workflow configuration to use the Sitemap Checker GitHub Action.

```yaml
name: Sitemap Check

on:
  workflow_dispatch:
    inputs:
      sitemap_url:
        description: 'The base URL of the sitemap, with a placeholder for locale'
        required: true
        default: 'https://www.example.com/{locale}/sitemap.xml'
      exclude:
        description: 'Comma separated list of domains to exclude'
        required: false
        default: 'microsoft.com,a.storyblok.com,_next,popages.com,youtube,facebook,instagram,object'
      slack_channel:
        description: 'The Slack channel to send results to.'
        required: true
        default: 'my-channel'
      slack_token:
        description: 'The Slack bot token to post messages.'
        required: true

  schedule:
    - cron: '0 6 * * *'

jobs:
  sitemap_check:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Run Sitemap Check Action
        uses: Andy1Blue/sitemap-check@v1
        with:
          sitemap_url: 'https://www.example.com/{locale}/sitemap.xml'
          exclude: 'example.com,anotherdomain.com'
          slack_channel: ${{ github.event.inputs.slack_channel }}
          slack_token: ${{ secrets.SLACK_TOKEN }}
