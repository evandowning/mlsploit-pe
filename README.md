# mlsploit-pe

## Clone repository
```
$ git clone --recursive https://github.com/evandowning/mlsploit-pe.git
```

## Tests
```
# Train
$ cp input/input-train-ensemble-example.json input/input.json
$ ./test.sh

# Evaluate
$ cp input/input-evaluation-ensemble-example.json input/input.json
$ ./test.sh

# Attack
$ cp input/input-transformation-example.json input/input.json
$ ./test.sh

# Evaluate attack
$ cp input/input-evaluation-ensemble-attack-example.json input/input.json
$ ./test.sh
```

## MLsploit notes
  * Modify `mlsploit-execution-backend/mlsploit.py`
    * `Git(tmp_dir).clone(repo)` -> `Git(tmp_dir).clone(repo,recursive=True)`
  * Modify `run.sh` to contain folder where samples are located and mount on docker in `mlsploit-execution-backend/mlsploit.py`
    * Current path is variable `RAW` in `run.sh`
