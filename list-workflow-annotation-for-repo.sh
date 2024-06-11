#!/bin/bash

function echostderr() {
  echo "$@" 1>&2
}

repo="$1"
if [ ! -n "${repo}" ]; then
  echostderr "Usage: $0 <owner>/<repo> > annotations.md"
  exit 1
fi

tmpdir="tmp"
mkdir -p "${tmpdir}"

echostderr 'List workflows for a repository'
gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" \
  "/repos/${repo}/actions/workflows" > "${tmpdir}/workflows.json"

for workflow_id in $(cat "${tmpdir}/workflows.json" | jq -r '.workflows[].id'); do
  echostderr "sleep 1"
  sleep 1

  workflow_name=$(cat "${tmpdir}/workflows.json" | jq -r ".workflows[] | select(.id == ${workflow_id}) | .name")
  workflow_html_url=$(cat "${tmpdir}/workflows.json" | jq -r ".workflows[] | select(.id == ${workflow_id}) | .html_url")
  echo "## [${workflow_name}](${workflow_html_url})"

  echostderr "List latest run for a workflow id: ${workflow_id}"
  gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/${repo}/actions/workflows/${workflow_id}/runs?per_page=1" > "${tmpdir}/runs-${workflow_id}.json"

  run_html_url=$(cat "${tmpdir}/runs-${workflow_id}.json" | jq -r '.workflow_runs[0].html_url')
  echo "Latest run: [${run_html_url}](${run_html_url})"

  check_suite_id=$(cat "${tmpdir}/runs-${workflow_id}.json" | jq -r '.workflow_runs[0].check_suite_id')

  echostderr "List check runs for a check suite id: ${check_suite_id}"
  gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" \
    "/repos/${repo}/check-suites/${check_suite_id}/check-runs" > "${tmpdir}/check-runs-${check_suite_id}.json"

  for check_run_id in $(cat "${tmpdir}/check-runs-${check_suite_id}.json" | jq -r '.check_runs[].id'); do
    echostderr "List annotations for a check run id: ${check_run_id}"


    check_run_name=$(cat "${tmpdir}/check-runs-${check_suite_id}.json" | jq -r ".check_runs[] | select(.id == ${check_run_id}) | .name")
    check_run_html_url=$(cat "${tmpdir}/check-runs-${check_suite_id}.json" | jq -r ".check_runs[] | select(.id == ${check_run_id}) | .html_url")
    echo ''
    echo "### [${check_run_name}](${check_run_html_url})"

    gh api -H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28" \
      "/repos/${repo}/check-runs/${check_run_id}/annotations" > "${tmpdir}/annotations-${check_run_id}.json"

    # output annotations
    # each annotation formatted in markdown code block
    cat "${tmpdir}/annotations-${check_run_id}.json" | jq -r '.[].message | "```\n" + . + "\n```"'
    echo ''
  done
done
