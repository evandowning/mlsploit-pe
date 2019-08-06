FROM debian:stretch

RUN apt update && apt install -y sudo default-jre jq python3 zip
RUN apt upgrade -y

workdir /app
RUN mkdir sequence
RUN mkdir existence
RUN mkdir frequency
RUN mkdir mimicry

# Setup sequence
workdir /app/sequence
ADD ./model-api-sequence ./
RUN ./setup.sh

# Setup existence
workdir /app/existence
ADD ./model-api-existence ./
RUN ./setup.sh

# Setup frequency
workdir /app/frequency
ADD ./model-api-frequency ./
RUN ./setup.sh

# Setup mimicry attack
workdir /app/mimicry
ADD ./mimicry-sequence ./
RUN ./setup.sh
RUN ./setup_neo4j.sh

# Add run (for Docker) and api.txt (for converting API calls to integers)
workdir /app
ADD ./run.sh /app
ADD ./label.txt /app

# If private repo exists, set up
COPY Dockerfile behavior-profile* /app/arguments/
RUN if [ -d arguments ]; then cd arguments; ./setup.sh; fi
COPY Dockerfile patch/patchPE* /app/petransformer/
RUN if [ -d petransformer ]; then cd petransformer; ./setup.sh; ./autorun.sh; fi

# Change permissions
RUN chown -R 1001:1001 /app/

CMD ["bash","run.sh"]
