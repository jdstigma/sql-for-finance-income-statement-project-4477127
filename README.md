# Codespaces build fix

The stock course devcontainer drops every new Codespace into a **recovery
container**. Two independent root causes:

1. The base image ships a yarn apt source whose GPG signing key is unavailable
   (`NO_PUBKEY 62D54FD4003F6525`), so `apt-get update` exits 100 and the **image
   build fails**.
2. `postgres:latest` now resolves to **PostgreSQL 18**, which refuses to start on
   the existing volume layout and crash-loops the database container.

To apply the same fix, change these files:

| File | Change |
|------|--------|
| `.devcontainer/Dockerfile` | Pin base to `mcr.microsoft.com/devcontainers/python:1-3.12-bookworm`; add `rm -f /etc/apt/sources.list.d/yarn.list` before `apt-get`; install `postgresql-client` with `--no-install-recommends`. |
| `.devcontainer/docker-compose.yml` | Pin db image to `postgres:15`; add a db `healthcheck` and `depends_on: db: condition: service_healthy` on the app service; remove the obsolete `version:` key. |
| `.devcontainer/startup.sh` | Add a `pg_isready` retry loop and make the data load idempotent (skip if the `payments` table already exists), since the SQL dump has no `DROP TABLE` guards. |
| `.devcontainer/devcontainer.json` | Run `postCreateCommand` with `bash` (not `sudo sh`); add `"forwardPorts": [5432]`; drop dead `python.linting.*`/`python.formatting.*` settings. |
| `.gitattributes` *(new file)* | Force **LF** on `*.sh`/`Dockerfile`/`*.yml`/`*.json` so a Windows checkout can't break `startup.sh` with CRLF (`bash: \r: command not found`); leave `*.sql` untouched. |
| `.vscode/settings.json` | Replace the removed `workbench.activityBar.visible` with `workbench.activityBar.location`. |
| `.github/workflows/main.yml` | Bump `actions/checkout@v2` → `@v4`. |

> **Note:** the app container shares the database container's network
> (`network_mode: service:db`), so the database is reached at `127.0.0.1`. After a
> fresh Codespace comes up, verify with:
> `psql -h 127.0.0.1 -U postgres -d postgres -c "\dt"` — you should see `loans`,
> `payments`, `purchases`, and `sales`. An already-failed Codespace will **not**
> pick up these changes; delete it and create a new one.

---

# SQL for Finance: Income Statement Project
This is the repository for the LinkedIn Learning course SQL for Finance: Income Statement Project. The full course is available from [LinkedIn Learning][lil-course-url].

![lil-thumbnail-url]

SQL is a powerful tool to have in your toolkit, when you need to create financial reports. How do you get started, though? In this course, data analytics expert Gabriela Baldivia Soncini guides you through the fundamental concepts of financial accounting via an income statement project. Learn how to extract data from a relational database, manipulate data using SQL queries, and transform the data. Find out how to prepare basic financial statements like balance sheets and income statements. Plus, solidify what you learn with a course-spanning project, as well as several hands-on challenges.

_See the readme file in the main branch for updated instructions and information._
## Instructions
This repository has branches for each of the videos in the course. You can use the branch pop up menu in github to switch to a specific branch and take a look at the course at that stage, or you can add `/tree/BRANCH_NAME` to the URL to go to the branch you want to access.

## Branches
The branches are structured to correspond to the videos in the course. The naming convention is `CHAPTER#_MOVIE#`. As an example, the branch named `02_03` corresponds to the second chapter and the third video in that chapter. 
Some branches will have a beginning and an end state. These are marked with the letters `b` for "beginning" and `e` for "end". The `b` branch contains the code as it is at the beginning of the movie. The `e` branch contains the code as it is at the end of the movie. The `main` branch holds the final state of the code when in the course.

When switching from one exercise files branch to the next after making changes to the files, you may get a message like this:

    error: Your local changes to the following files would be overwritten by checkout:        [files]
    Please commit your changes or stash them before you switch branches.
    Aborting

To resolve this issue:
	
    Add changes to git using this command: git add .
	Commit changes using this command: git commit -m "some message"


[0]: # (Replace these placeholder URLs with actual course URLs)

[lil-course-url]: https://www.linkedin.com/learning/sql-for-finance-income-statement-project
[lil-thumbnail-url]: https://media.licdn.com/dms/image/D560DAQGAS3pGv_t8BQ/learning-public-crop_675_1200/0/1704486338824?e=2147483647&v=beta&t=BE78saEottvl0JVr3UPfrcuMM8cOpxNdXV-3XE96HtY
