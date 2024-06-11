# list-workflow-annotation-for-repo

Lists all workflow annotations for a repo in markdown

## Usage

- warning: this script requests many GitHub API with gh command https://cli.github.com/

```sh
$ gh auth login
$ ./list-workflow-annotation-for-repo.sh owner/repo > annotations.md
```

- [Example output](./example-output.md)
