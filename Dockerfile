FROM debian:buster

RUN apt update && apt install -y sudo default-jre jq python3 zip wget
RUN apt upgrade -y

workdir /app
RUN mkdir sequence
RUN mkdir existence
RUN mkdir frequency
RUN mkdir mimicry
RUN mkdir arguments
RUN mkdir petransformer
RUN mkdir ember

# Setup sequence
#   workdir /app/sequence
#   COPY ./model-api-sequence ./
#   RUN ./setup.sh

# Setup existence
#   workdir /app/existence
#   COPY ./model-api-existence ./
#   RUN ./setup.sh

# Setup frequency
#   workdir /app/frequency
#   COPY ./model-api-frequency ./
#   RUN ./setup.sh

# Setup ember
workdir /app/ember
COPY ./ember ./
RUN ./setup.sh

# Setup mimicry attack
#   workdir /app/mimicry
#   COPY ./mimicry-sequence ./
#   RUN ./setup.sh
#   RUN ./setup_neo4j.sh

# Setup ember attack
workdir /app/ember-attack
COPY ./gym-malware ./
RUN ./setup.sh

# Add run (for Docker) and api.txt (for converting API calls to integers)
workdir /app
COPY ./run.sh /app
COPY ./label.txt /app

# If private repo exists, set up
workdir /app/arguments
COPY ./behavior-profile ./
RUN if [ -f setup.sh ]; then ./setup.sh; fi

# If private repo exists, set up
workdir /app/petransformer
COPY ./patch/patchPE ./
RUN if [ -f setup.sh ]; then ./setup.sh; ./autorun.sh; fi

# Change permissions
RUN chown -R 1001:1001 /app/

workdir /app
CMD ["bash","run.sh"]
