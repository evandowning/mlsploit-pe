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
  * Create MLSploit configuration file via `$ python _buildmodule.py`
    * First install `https://github.com/mlsploit/mlsploit-py`
