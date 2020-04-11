from mlsploit import Module

#TODO - change to "master" branch after finishing
IMG_URL='https://github.com/evandowning/mlsploit-pe/raw/develop/static/pe.png'

module = Module.build(
    display_name='PE Module',
    tagline='This is the PE module',
    doctxt="""Module to train and attack PE models.""",
    icon_url=IMG_URL)

###########################################
# Create model ensemble training function #
###########################################
function = module.build_function(
    name='Ensemble-Train',
    doctxt="""Trains an ensemble of models on PE features. Takes .train.txt file as input.""",
    creates_new_files=True,
    modifies_input_files=True,
    expected_filetype='.train.txt',
    optional_filetypes=['.eval.txt'])

# API sequence
function.add_option(
    name='sequence',
    type='bool',
    default=False,
    doctxt="""Sequence - Enable""",
    required=True)
function.add_option(
    name='sequence_window',
    type='int',
    default=32,
    doctxt="""Sequence - Window Size""",
    required=True)
function.add_option(
    name='sequence_type',
    type='enum',
    enum_values=['multi_classification','binary_classification'],
    default='binary_classification',
    doctxt="""Sequence - Classification Type""",
    required=True)
function.add_option(
    name='sequence_lstm',
    type='bool',
    default=False,
    doctxt="""Sequence - LSTM - Enable""",
    required=True)
function.add_option(
    name='sequence_rnn',
    type='bool',
    default=False,
    doctxt="""Sequence - RNN - Enable""",
    required=True)
function.add_option(
    name='sequence_cnn',
    type='bool',
    default=False,
    doctxt="""Sequence - CNN - Enable""",
    required=True)

# API existence
function.add_option(
    name='existence',
    type='bool',
    default=False,
    doctxt="""Existence - Enable""",
    required=True)
function.add_option(
    name='existence_rf',
    type='bool',
    default=False,
    doctxt="""Existence - Random Forest - Enable""",
    required=True)
function.add_option(
    name='existence_rf_trees',
    type='int',
    default=10,
    doctxt="""Existence - Random Forest - Number of Trees""",
    required=True)
function.add_option(
    name='existence_nb',
    type='bool',
    default=False,
    doctxt="""Existence - Naive Bayes - Enable""",
    required=True)
function.add_option(
    name='existence_knn',
    type='bool',
    default=False,
    doctxt="""Existence - k-Nearest Neighbors - Enable""",
    required=True)
function.add_option(
    name='existence_knn_k',
    type='int',
    default=5,
    doctxt="""Existence - k-Nearest Neighbors - k-value""",
    required=True)
function.add_option(
    name='existence_sgd',
    type='bool',
    default=False,
    doctxt="""Existence - Stochastic Gradient Descent - Enable""",
    required=True)
function.add_option(
    name='existence_mlp',
    type='bool',
    default=False,
    doctxt="""Existence - Multi-Layer Perceptron - Enable""",
    required=True)

# API frequency
function.add_option(
    name='frequency',
    type='bool',
    default=False,
    doctxt="""Frequency - Enable""",
    required=True)
function.add_option(
    name='frequency_rf',
    type='bool',
    default=False,
    doctxt="""Frequency - Random Forest - Enable""",
    required=True)
function.add_option(
    name='frequency_rf_trees',
    type='int',
    default=10,
    doctxt="""Frequency - Random Forest - Number of Trees""",
    required=True)
function.add_option(
    name='frequency_nb',
    type='bool',
    default=False,
    doctxt="""Frequency - Naive Bayes - Enable""",
    required=True)
function.add_option(
    name='frequency_knn',
    type='bool',
    default=False,
    doctxt="""Frequency - k-Nearest Neighbors - Enable""",
    required=True)
function.add_option(
    name='frequency_knn_k',
    type='int',
    default=5,
    doctxt="""Frequency - k-Nearest Neighbors - k-value""",
    required=True)
function.add_option(
    name='frequency_sgd',
    type='bool',
    default=False,
    doctxt="""Frequency - Stochastic Gradient Descent - Enable""",
    required=True)
function.add_option(
    name='frequency_mlp',
    type='bool',
    default=False,
    doctxt="""Frequency - Multi-Layer Perceptron - Enable""",
    required=True)

# API arguments
function.add_option(
    name='arguments',
    type='bool',
    default=False,
    doctxt="""Arguments - Enable""",
    required=True)
function.add_option(
    name='arguments_rf',
    type='bool',
    default=False,
    doctxt="""Arguments - Random Forest - Enable""",
    required=True)
function.add_option(
    name='arguments_rf_trees',
    type='int',
    default=10,
    doctxt="""Arguments - Random Forest - Number of Trees""",
    required=True)
function.add_option(
    name='arguments_nb',
    type='bool',
    default=False,
    doctxt="""Arguments - Naive Bayes - Enable""",
    required=True)
function.add_option(
    name='arguments_knn',
    type='bool',
    default=False,
    doctxt="""Arguments - k-Nearest Neighbors - Enable""",
    required=True)
function.add_option(
    name='arguments_knn_k',
    type='int',
    default=5,
    doctxt="""Arguments - k-Nearest Neighbors - k-value""",
    required=True)
function.add_option(
    name='arguments_sgd',
    type='bool',
    default=False,
    doctxt="""Arguments - Stochastic Gradient Descent - Enable""",
    required=True)
function.add_option(
    name='arguments_mlp',
    type='bool',
    default=False,
    doctxt="""Arguments - Multi-Layer Perceptron - Enable""",
    required=True)

#############################################
# Create model ensemble evaluating function #
#############################################
function = module.build_function(
    name='Ensemble-Evaluate',
    doctxt="""Evaluates an ensemble of trained models. Takes .eval.txt and .model.zip as input.""",
    creates_new_files=True,
    modifies_input_files=True,
    expected_filetype='.eval.txt',
    optional_filetypes=['.model.zip'])
function.add_option(
    name='sequence',
    type='bool',
    default=False,
    doctxt="""Sequence - Enable""",
    required=True)
function.add_option(
    name='sequence_window',
    type='int',
    default=32,
    doctxt="""Sequence - Window Size""",
    required=True)
function.add_option(
    name='sequence_type',
    type='enum',
    enum_values=['multi_classification','binary_classification'],
    default='multi_classification',
    doctxt="""Sequence - Classification Type""",
    required=True)
function.add_option(
    name='existence',
    type='bool',
    default=False,
    doctxt="""Existence - Enable""",
    required=True)
function.add_option(
    name='frequency',
    type='bool',
    default=False,
    doctxt="""Frequency - Enable""",
    required=True)
function.add_option(
    name='arguments',
    type='bool',
    default=False,
    doctxt="""Arguments - Enable""",
    required=True)

##################################
# Create mimicry attack function #
##################################
function = module.build_function(
    name='Mimicry-Attack',
    doctxt="""Performs mimicry attack. Takes .benign.txt, .target.txt, and .model.zip as input.""",
    creates_new_files=True,
    modifies_input_files=False,
    expected_filetype='.benign.txt',
    optional_filetypes=['.target.txt','.model.zip'])
function.add_option(
    name='sequence',
    type='bool',
    default=False,
    doctxt="""Sequence - Enable""",
    required=True)
function.add_option(
    name='sequence_window',
    type='int',
    default=32,
    doctxt="""Sequence - Window Size""",
    required=True)
function.add_option(
    name='sequence_type',
    type='enum',
    enum_values=['multi_classification','binary_classification'],
    default='multi_classification',
    doctxt="""Sequence - Classification Type""",
    required=True)
function.add_option(
    name='generations',
    type='int',
    default=1,
    doctxt="""Number of attack samples to generate""",
    required=True)

##################################
# Create PE transformer function #
##################################
function = module.build_function(
    name='PE-Transformer',
    doctxt="""Statically modifies PE binary to exhibit attack. Takes .cfg.zip as input.""",
    creates_new_files=True,
    modifies_input_files=False,
    expected_filetype='.cfg.zip',
    optional_filetypes=[])
function.add_option(
    name='hash',
    type='str',
    doctxt="""SHA-256 hash value of binary to transform.""",
    required=True)

########################################
# Create trampoline detection function #
########################################
function = module.build_function(
    name='Detect-Trampoline',
    doctxt="""Trains model to detect trampoline insertion. Takes .nominal.txt and .test.txt as input.""",
    creates_new_files=True,
    modifies_input_files=False,
    expected_filetype='.nominal.txt',
    optional_filetypes=['.test.txt'])

# Save yaml file
module.save()
