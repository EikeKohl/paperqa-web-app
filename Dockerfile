FROM python:3.10-slim-bullseye

# Set working directory and copy files
WORKDIR /app
COPY poetry.lock /app
COPY pyproject.toml /app

# Install requirements
RUN apt-get update && \
    apt-get install curl --no-install-recommends -y

ENV POETRY_VIRTUALENVS_CREATE=false \
    PATH="/root/.local/bin:$PATH"
RUN curl -sSL https://install.python-poetry.org | python3 -
RUN poetry install --no-interaction --only main

COPY paperqa/ /app/paperqa
COPY src/ /app/src
COPY app.py /app

# Set the entrypoint and allow additional CLI arguments to be passed
CMD ["printenv"]
ENTRYPOINT ["streamlit", "run", "app.py"]
