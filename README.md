# mlsploit-pe

## Clone repository
```
$ git clone --recursive git@github.com:evandowning/mlsploit-pe.git
```

## Tests
```
# Train
$ cp input/input-train-ensemble-example.json input/input.json
$ ./test.sh

# Evaluate
$ cp output/pe.model.zip input/
$ cp input/input-evaluation-ensemble-example.json input/input.json
$ ./test.sh

# Mimicry Attack
$ cp input/input-mimicry-example.json input/input.json
$ ./test.sh

# Transformation
$ cp output/attack.cfg.zip input/
$ cp input/input-transformation-mimicry-example.json input/input.json
$ ./test.sh

# Bonus
$ cp input/input-ember-train.json input/input.json
$ ./test.sh
$ cp input/input-ember-evaluation.json input/input.json
$ ./test.sh
$ cp input/input-ember-attack.json input/input.json
$ ./test.sh
```

## MLSploit notes
  * Create MLSploit configuration file via `$ python _buildmodule.py`
    * First install `https://github.com/mlsploit/mlsploit-py`
