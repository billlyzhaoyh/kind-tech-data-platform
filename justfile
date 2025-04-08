# Repository-wide commands.
# Read https://github.com/casey/just#quick-start before editing.

excludes := "-e admin -e auth.permission -e contenttypes -e sessions -e silk"

# Default command, do not add any commands above it.
default:
  @just dev

dev:
    uv run ./manage.py runserver

celery:
    watchexec -w apps -e py -r "uv run celery -A kindtech worker -Q celery,priority -l INFO"

beat:
    watchexec -w apps -e py -r "uv run celery -A kindtech beat -l INFO"

migrate app='' migration='':
    uv run ./manage.py migrate {{app}} {{migration}}

shell:
    ./manage.py shell -i ipython

collectstatic:
    ./manage.py collectstatic --noinput

celery-ci:
    uv run celery -A kindtech worker -l info

compile:
    # TODO: remove dependency on django-heroku
    uv pip compile --generate-hashes -o requirements.txt requirements.in
    uv pip compile --generate-hashes -o requirements-dev.txt requirements-dev.in

sync:
    uv pip sync requirements.txt requirements-dev.txt

update:
    npm install
    sync

req:
    uv pip install -r requirements.txt

req-dev:
    uv pip install -r requirements-dev.txt

format:
    uv run autoflake --in-place --recursive --remove-all-unused-imports --ignore-init-module-imports --exclude 'apps/*/migrations' kindtech apps
    uv run black .
    uv run isort .

alias bf := branchformat
branchformat:
    git diff --diff-filter=M --name-only main '***.scss' | xargs --no-run-if-empty npm run prettier:write
    git diff --diff-filter=M --name-only main '***.py' | xargs --no-run-if-empty black
    git diff --diff-filter=M --name-only main '***.py' | xargs --no-run-if-empty isort

# Count total lines of code that need to be maintained
cloc:
    cloc $(git ls-files) --exclude-dir=migrations,tests,vendors --exclude-ext=svg,csv,json,yaml,md,toml

startapp:
    pushd apps && cookiecutter cookiecutter-app && popd

test TEST=".":
    python -m pytest --no-migrations --ignore=apps/base/tests/e2e --ignore=apps/cookiecutter-app --disable-pytest-warnings -k {{TEST}}

test-ci:
    python -m pytest --cov --cov-report xml --no-migrations --disable-pytest-warnings --ignore=apps/base/tests/e2e --ignore=apps/cookiecutter-app

test-e2e:
    python -m pytest --no-migrations --disable-pytest-warnings --tracing=retain-on-failure --reruns 2 apps/base/tests/e2e
