#!/bin/bash

# Function if error occured
function exit_error() {
    NAME="$1"
    LOG_NAME="$2"
    LOG_ERR_NAME="$3"
    OUTPUT="$4"

    # Write output.json
    echo '{
    "name": "'"$NAME"'",
    "files": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'"],
    "tags": [{"ftype":"log"},{"ftype":"log"}],
    "files_created": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'"],
    "files_modified": []
    }' > "$OUTPUT/output.json"

    exit 0
}

# Function to parse data files
function parse_file() {
    CONFIG="$1"
    EXT="$2"

    # Get number of files passed
    NUM_FILES=$( jq -r ".num_files | length" "$CONFIG")

    if [ $NUM_FILES -gt 0 ]; then
        for i in `seq 0 $((NUM_FILES-1))`
        do
            e=$( jq -r ".files"[$i] "$CONFIG" )

            # If this is the targeted file extension
            if [[ "$e" == *"$EXT" ]]; then
                echo "$e"
                return
            fi
        done
    fi

    echo ""
}

set -x

END="============================================="

INPUT="/mnt/input"
OUTPUT="/mnt/output"
RAW="/mnt/malwarelab"
BINARY="/mnt/binary"

CONFIG="$INPUT/input.json"
NAME=$( jq -r ".name" "$CONFIG" )

LOG_NAME="pe-${NAME}.log.txt"
LOG_ERR_NAME="pe-${NAME}.log_err.txt"
LOG="$OUTPUT/$LOG_NAME"
LOG_ERR="$OUTPUT/$LOG_ERR_NAME"

echo "Started: `date +%s`" > $LOG
echo "" > $LOG_ERR

echo "Running $NAME" >> $LOG

# Get number of files passed
NUM_FILES=$( jq -r ".num_files | length" "$CONFIG")

# MODEL_ENSEMBLE
if [ "$NAME" = "Ensemble-Train" ]; then
    # Get files
    CLASSES=$(parse_file "$CONFIG" ".train.txt")

    # Check input files
    if [ "$CLASSES" = "" ]; then
        echo "Error. Couldn't find input files." >> $LOG_ERR
        exit_error "$NAME" "$LOG_NAME" "$LOG_ERR_NAME" "$OUTPUT"
    fi

    # Folder where extraction code exists
    EXTRACT="cuckoo-headless/extract_raw/"

    # Models folder which will get compressed and sent back to user
    mkdir "$OUTPUT/model/"

    # SEQUENCE
    if [ $( jq ".options.sequence" "$CONFIG" ) = true ]; then

        # Get sequence length
        SEQUENCE_WINDOW=$( jq ".options.sequence_window" "$CONFIG" )

        # Get sequence modeling type
        SEQUENCE_TYPE=$( jq -r ".options.sequence_type" "$CONFIG" )

        # Get ensemble options
        SEQUENCE_LSTM=false
        SEQUENCE_RNN=false
        SEQUENCE_CNN=false
        if [ $( jq ".options.sequence_lstm" "$CONFIG" ) = true ]; then
            SEQUENCE_LSTM=true
        fi
        if [ $( jq ".options.sequence_rnn" "$CONFIG" ) = true ]; then
            SEQUENCE_RNN=true
        fi
        if [ $( jq ".options.sequence_cnn" "$CONFIG" ) = true ]; then
            SEQUENCE_CNN=true
        fi

        cd /app/sequence/

        mkdir "$OUTPUT/model/api-sequence"

        # Extract sequences
        echo "Extracting sequences" >> $LOG
        echo "Extracting sequences" >> $LOG_ERR
        echo "Start Timestamp: `date +%s`" >> $LOG
        cd "$EXTRACT"
        python2.7 extract-sequence.py "$RAW" "$INPUT/$CLASSES" "/app/sequence/api-sequences/" >> $LOG 2>> $LOG_ERR
        cd ../..
        echo "End Timestamp: `date +%s`" >> $LOG
        echo $END >> $LOG
        echo $END >> $LOG_ERR

        # Extract features
        echo "Extracting features" >> $LOG
        echo "Extracting features" >> $LOG_ERR
        echo "Start Timestamp: `date +%s`" >> $LOG
        python3 preprocess.py "api-sequences/" "$EXTRACT/api.txt" "/app/label.txt" "$INPUT/$CLASSES" "api-sequence-features/" $SEQUENCE_WINDOW $SEQUENCE_TYPE >> $LOG 2>> $LOG_ERR
        echo "End Timestamp: `date +%s`" >> $LOG
        echo $END >> $LOG
        echo $END >> $LOG_ERR

        #TODO
        # Train models
        if [ $SEQUENCE_LSTM = true ]; then
            echo "Training LSTM model" >> $LOG
            echo "Training LSTM model" >> $LOG_ERR
            echo "Start Timestamp: `date +%s`" >> $LOG
            #python3 lstm.py "$EXTRACT/api.txt" "api-sequence-features/" "$OUTPUT/model/api-sequence/lstm/" True False $SEQUENCE_TYPE "$OUTPUT/model/api-sequence/lstm/convert_classes.txt" >> $LOG 2>> $LOG_ERR
            python3 lstm.py "$EXTRACT/api.txt" "api-sequence-features/" "$OUTPUT/model/api-sequence/lstm/" True False $SEQUENCE_TYPE "$OUTPUT/model/api-sequence/lstm/convert_classes.txt"
            echo "BLAH"
            echo "End Timestamp: `date +%s`" >> $LOG
            echo $END >> $LOG
            echo $END >> $LOG_ERR
        fi

        if [ $SEQUENCE_RNN = true ]; then
            echo "Training RNN model" >> $LOG
            echo "Training RNN model" >> $LOG_ERR
            echo "Start Timestamp: `date +%s`" >> $LOG
            #python3 rnn.py "$EXTRACT/api.txt" "api-sequence-features/" "$OUTPUT/model/api-sequence/rnn/" True False $SEQUENCE_TYPE "$OUTPUT/model/api-sequence/rnn/convert_classes.txt" >> $LOG 2>> $LOG_ERR
            python3 rnn.py "$EXTRACT/api.txt" "api-sequence-features/" "$OUTPUT/model/api-sequence/rnn/" True False $SEQUENCE_TYPE "$OUTPUT/model/api-sequence/rnn/convert_classes.txt"
            echo "BLAH"
            echo "End Timestamp: `date +%s`" >> $LOG
            echo $END >> $LOG
            echo $END >> $LOG_ERR
        fi

        if [ $SEQUENCE_CNN = true ]; then
            echo "Training CNN model" >> $LOG
            echo "Training CNN model" >> $LOG_ERR
            echo "Start Timestamp: `date +%s`" >> $LOG
            #python3 cnn.py "$EXTRACT/api.txt" "api-sequence-features/" "$OUTPUT/model/api-sequence/cnn/" True False $SEQUENCE_TYPE "$OUTPUT/model/api-sequence/cnn/convert_classes.txt" >> $LOG 2>> $LOG_ERR
            python3 cnn.py "$EXTRACT/api.txt" "api-sequence-features/" "$OUTPUT/model/api-sequence/cnn/" True False $SEQUENCE_TYPE "$OUTPUT/model/api-sequence/cnn/convert_classes.txt"
            echo "BLAH"
            echo "End Timestamp: `date +%s`" >> $LOG
            echo $END >> $LOG
            echo $END >> $LOG_ERR
        fi

        cd /app/
    fi

    # EXISTENCE
    if [ $( jq ".options.existence" "$CONFIG" ) = true ]; then
        cd /app/existence/

        mkdir "$OUTPUT/model/api-existence"

        # String to construct parameters
        EXISTENCE_PARAM=""

        # Get ensemble options
        if [ $( jq ".options.existence_rf" "$CONFIG" ) = true ]; then
            EXISTENCE_PARAM+=" --rf_model $OUTPUT/model/api-existence/model_rf.pkl"
        fi
        if [ $( jq ".options.existence_rf_trees" "$CONFIG" ) != null ]; then
            EXISTENCE_RF_TREES=$( jq ".options.existence_rf_trees" "$CONFIG" )
            EXISTENCE_PARAM+=" --trees $EXISTENCE_RF_TREES"
        fi
        if [ $( jq ".options.existence_nb" "$CONFIG" ) = true ]; then
            EXISTENCE_PARAM+=" --nb_model $OUTPUT/model/api-existence/model_nb.pkl"
        fi
        if [ $( jq ".options.existence_knn" "$CONFIG" ) = true ]; then
            EXISTENCE_PARAM+=" --knn_model $OUTPUT/model/api-existence/model_knn.pkl"
        fi
        if [ $( jq ".options.existence_knn_k" "$CONFIG" ) != null ]; then
            EXISTENCE_KNN_K=$( jq ".options.existence_knn_k" "$CONFIG" )
            EXISTENCE_PARAM+=" --k $EXISTENCE_KNN_K"
        fi
        if [ $( jq ".options.existence_sgd" "$CONFIG" ) = true ]; then
            EXISTENCE_PARAM+=" --sgd_model $OUTPUT/model/api-existence/model_sgd.pkl"
        fi
        if [ $( jq ".options.existence_mlp" "$CONFIG" ) = true ]; then
            EXISTENCE_PARAM+=" --mlp_model $OUTPUT/model/api-existence/model_mlp.pkl"
        fi

        # Extract features
        echo "Extracting existence features" >> $LOG
        echo "Extracting existence features" >> $LOG_ERR
        echo "Start Timestamp: `date +%s`" >> $LOG
        cd "$EXTRACT"
        python2.7 extract-existence.py "$RAW" "api.txt" "/app/label.txt" "$INPUT/$CLASSES" "/app/existence/api-existence.csv" >> $LOG 2>> $LOG_ERR
        cd ../..
        echo "End Timestamp: `date +%s`" >> $LOG
        echo $END >> $LOG
        echo $END >> $LOG_ERR

        # Train models
        echo "Training models" >> $LOG
        echo "Training models" >> $LOG_ERR
        echo "Start Timestamp: `date +%s`" >> $LOG
        python3 api_existence.py    --csv "api-existence.csv" \
                                    --ensemble_model "$OUTPUT/model/api-existence/model_ensemble.pkl" \
                                    $EXISTENCE_PARAM \
                                    >> $LOG 2>> $LOG_ERR
        echo "End Timestamp: `date +%s`" >> $LOG
        echo $END >> $LOG
        echo $END >> $LOG_ERR

        cd /app/
    fi

    # FREQUENCY
    if [ $( jq ".options.frequency" "$CONFIG" ) = true ]; then
        cd /app/frequency/

        mkdir "$OUTPUT/model/api-frequency"

        # String to construct parameters
        FREQUENCY_PARAM=""

        # Get ensemble options
        if [ $( jq ".options.frequency_rf" "$CONFIG" ) = true ]; then
            FREQUENCY_PARAM+=" --rf_model $OUTPUT/model/api-frequency/model_rf.pkl"
        fi
        if [ $( jq ".options.frequency_rf_trees" "$CONFIG" ) != null ]; then
            FREQUENCY_RF_TREES=$( jq ".options.frequency_rf_trees" "$CONFIG" )
            FREQUENCY_PARAM+=" --trees $FREQUENCY_RF_TREES"
        fi
        if [ $( jq ".options.frequency_nb" "$CONFIG" ) = true ]; then
            FREQUENCY_PARAM+=" --nb_model $OUTPUT/model/api-frequency/model_nb.pkl"
        fi
        if [ $( jq ".options.frequency_knn" "$CONFIG" ) = true ]; then
            FREQUENCY_PARAM+=" --knn_model $OUTPUT/model/api-frequency/model_knn.pkl"
        fi
        if [ $( jq ".options.frequency_knn_k" "$CONFIG" ) != null ]; then
            FREQUENCY_KNN_K=$( jq ".options.frequency_knn_k" "$CONFIG" )
            FREQUENCY_PARAM+=" --k $FREQUENCY_KNN_K"
        fi
        if [ $( jq ".options.frequency_sgd" "$CONFIG" ) = true ]; then
            FREQUENCY_PARAM+=" --sgd_model $OUTPUT/model/api-frequency/model_sgd.pkl"
        fi
        if [ $( jq ".options.frequency_mlp" "$CONFIG" ) = true ]; then
            FREQUENCY_PARAM+=" --mlp_model $OUTPUT/model/api-frequency/model_mlp.pkl"
        fi

        # Extract features
        echo "Extracting frequency features" >> $LOG
        echo "Extracting frequency features" >> $LOG_ERR
        echo "Start Timestamp: `date +%s`" >> $LOG
        cd "$EXTRACT"
        python2.7 extract-frequency.py "$RAW" "api.txt" "/app/label.txt" "$INPUT/$CLASSES" "/app/frequency/api-frequency.csv" >> $LOG 2>> $LOG_ERR
        cd ../../
        echo "End Timestamp: `date +%s`" >> $LOG
        echo $END >> $LOG
        echo $END >> $LOG_ERR

        # Train model
        echo "Training models" >> $LOG
        echo "Training models" >> $LOG_ERR
        echo "Start Timestamp: `date +%s`" >> $LOG
        python3 api_frequency.py    --csv "api-frequency.csv" \
                                    --ensemble_model "$OUTPUT/model/api-frequency/model_ensemble.pkl" \
                                    $FREQUENCY_PARAM \
                                    >> $LOG 2>> $LOG_ERR
        echo "End Timestamp: `date +%s`" >> $LOG
        echo $END >> $LOG
        echo $END >> $LOG_ERR

        cd /app/
    fi

    # ARGUMENTS
    if [ $( jq ".options.arguments" "$CONFIG" ) = true ]; then
        cd /app/arguments/

        mkdir "$OUTPUT/model/arguments"

        # String to construct parameters
        ARGUMENTS_PARAM=""

        # Get ensemble options
        if [ $( jq ".options.arguments_rf" "$CONFIG" ) = true ]; then
            ARGUMENTS_PARAM+=" --rf_model $OUTPUT/model/arguments/model_rf.pkl"
        fi
        if [ $( jq ".options.arguments_rf_trees" "$CONFIG" ) != null ]; then
            ARGUMENTS_RF_TREES=$( jq ".options.arguments_rf_trees" "$CONFIG" )
            ARGUMENTS_PARAM+=" --trees $ARGUMENTS_RF_TREES"
        fi
        if [ $( jq ".options.arguments_nb" "$CONFIG" ) = true ]; then
            ARGUMENTS_PARAM+=" --nb_model $OUTPUT/model/arguments/model_nb.pkl"
        fi
        if [ $( jq ".options.arguments_knn" "$CONFIG" ) = true ]; then
            ARGUMENTS_PARAM+=" --knn_model $OUTPUT/model/arguments/model_knn.pkl"
        fi
        if [ $( jq ".options.arguments_knn_k" "$CONFIG" ) != null ]; then
            ARGUMENTS_KNN_K=$( jq ".options.arguments_knn_k" "$CONFIG" )
            ARGUMENTS_PARAM+=" --k $ARGUMENTS_KNN_K"
        fi
        if [ $( jq ".options.arguments_sgd" "$CONFIG" ) = true ]; then
            ARGUMENTS_PARAM+=" --sgd_model $OUTPUT/model/arguments/model_sgd.pkl"
        fi
        if [ $( jq ".options.arguments_mlp" "$CONFIG" ) = true ]; then
            ARGUMENTS_PARAM+=" --mlp_model $OUTPUT/model/arguments/model_mlp.pkl"
        fi

        # Extract features
        echo "Extracting argument features" >> $LOG
        echo "Extracting argument features" >> $LOG_ERR
        echo "Start Timestamp: `date +%s`" >> $LOG
        cd extract_raw/
        python2.7 extract.py "$RAW" "$INPUT/$CLASSES" "/app/arguments/behavior_profiles/" >> $LOG 2>> $LOG_ERR
        python2.7 feature_set_to_minhash.py "/app/arguments/behavior_profiles/" "$INPUT/$CLASSES" "/app/arguments/behavior_profiles_minhash/" >> $LOG 2>> $LOG_ERR
        cd ../
        echo "End Timestamp: `date +%s`" >> $LOG
        echo $END >> $LOG
        echo $END >> $LOG_ERR

        # Train model
        echo "Training models" >> $LOG
        echo "Training models" >> $LOG_ERR
        echo "Start Timestamp: `date +%s`" >> $LOG
        cd ml_model/
        python2.7 ml_profiles.py    --sample "$INPUT/$CLASSES" \
                                    --label "/app/label.txt" \
                                    --minhash "/app/arguments/behavior_profiles_minhash/" \
                                    --ensemble_model "$OUTPUT/model/arguments/model_ensemble.pkl" \
                                    $ARGUMENTS_PARAM \
                                    >> $LOG 2>> $LOG_ERR
        echo "End Timestamp: `date +%s`" >> $LOG
        echo $END >> $LOG
        echo $END >> $LOG_ERR

        cd /app/
    fi

    # Compress models and move them to output folder
    cd "$OUTPUT"
    zip -r "$OUTPUT/pe.model.zip" "./model/"
    cd /app/

    # If eval data file was passed, add it to files_modified[]
    # so mlsploit frontend will pass it to next in pipeline
    EVAL=$(parse_file "$CONFIG" ".eval.txt")

    if [ "$EVAL" = "" ]; then
        # Write output.json
        echo '{
        "name": "'"$NAME"'",
        "files": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'","pe.model.zip"],
        "tags": [{"ftype":"log"},{"ftype":"log"},{"ftype":"model"}],
        "files_created": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'","pe.model.zip"],
        "files_modified": []
        }' > "$OUTPUT/output.json"

    else
        # Copy eval data file to output folder
        cp "$INPUT/$EVAL" "$OUTPUT/$EVAL"

        # Write output.json
        echo '{
        "name": "'"$NAME"'",
        "files": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'","pe.model.zip","'"$EVAL"'"],
        "tags": [{"ftype":"log"},{"ftype":"log"},{"ftype":"model"},{"ftype":"data"}],
        "files_created": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'","pe.model.zip"],
        "files_modified": ["'"$EVAL"'"]
        }' > "$OUTPUT/output.json"
    fi

fi

# EVALUATE_MODEL_ENSEMBLE
if [ "$NAME" = "Ensemble-Evaluate" ]; then
    # Get files
    CLASSES=$(parse_file "$CONFIG" ".eval.txt")
    MODEL_ZIP=$(parse_file "$CONFIG" ".model.zip")

    # Check input files
    if [ "$CLASSES" = "" ] || [ "$MODEL_ZIP" = "" ]; then
        echo "Error. Couldn't find input files." >> $LOG_ERR
        exit_error "$NAME" "$LOG_NAME" "$LOG_ERR_NAME" "$OUTPUT"
    fi

    # Folder where extraction code exists
    EXTRACT="cuckoo-headless/extract_raw/"

    # Get model(s)
    OLD_NAME=$( zipinfo -1 "$INPUT/$MODEL_ZIP" | head -1 | awk '{split($NF,a,"/");print a[1]}' )
    MODEL="model"

    # Unzip models
    cd "$INPUT"
    unzip "$MODEL_ZIP" -d "$OUTPUT"
    cd "$OUTPUT"
    mv $OLD_NAME $MODEL
    cd /app/

    # Predictions folder which will get compressed and sent back to user
    mkdir "$OUTPUT/prediction/"

    # SEQUENCE
    if [ $( jq ".options.sequence" "$CONFIG" ) = true ]; then
        # Get sequence length
        SEQUENCE_WINDOW=$( jq ".options.sequence_window" "$CONFIG" )

        SEQUENCE_TYPE=$( jq -r ".options.sequence_type" "$CONFIG" )

        cd /app/sequence/

        # Extract sequences
        echo "Extracting sequences" >> $LOG
        echo "Extracting sequences" >> $LOG_ERR
        echo "Start Timestamp: `date +%s`" >> $LOG
        cd "$EXTRACT"
        python2.7 extract-sequence.py "$RAW" "$INPUT/$CLASSES" "/app/sequence/api-sequences/" >> $LOG 2>> $LOG_ERR
        cd ../..
        echo "End Timestamp: `date +%s`" >> $LOG
        echo $END >> $LOG
        echo $END >> $LOG_ERR

        # Extract features
        echo "Extracting features" >> $LOG
        echo "Extracting features" >> $LOG_ERR
        echo "Start Timestamp: `date +%s`" >> $LOG
        python3 preprocess.py "api-sequences/" "$EXTRACT/api.txt" "/app/label.txt" "$INPUT/$CLASSES" "api-sequence-features/" $SEQUENCE_WINDOW $SEQUENCE_TYPE >> $LOG 2>> $LOG_ERR
        echo "End Timestamp: `date +%s`" >> $LOG
        echo $END >> $LOG
        echo $END >> $LOG_ERR

        # If LSTM was trained
        if [ -d "$OUTPUT/$MODEL/api-sequence/lstm/" ]; then
            echo "Evaluating model" >> $LOG
            echo "Evaluating model" >> $LOG_ERR
            echo "Start Timestamp: `date +%s`" >> $LOG
            # If there's a second file, then get the convert_classes file
            if [ "$OUTPUT/$MODEL/api-sequence/lstm/convert_classes.txt" != "" ]; then
                python3 evaluation.py "$OUTPUT/$MODEL/api-sequence/lstm/fold1-model.json" "$OUTPUT/$MODEL/api-sequence/lstm/fold1-weight.h5" "api-sequence-features/" "$INPUT/$CLASSES" "/app/label.txt" "$OUTPUT/prediction/api-sequence-lstm.csv" "$OUTPUT/$MODEL/api-sequence/lstm/convert_classes.txt" >> $LOG 2>> $LOG_ERR
            else
                python3 evaluation.py "$OUTPUT/$MODEL/api-sequence/lstm/fold1-model.json" "$OUTPUT/$MODEL/api-sequence/lstm/fold1-weight.h5" "api-sequence-features/" "$INPUT/$CLASSES" "/app/label.txt" "$OUTPUT/prediction/api-sequence-lstm.csv" >> $LOG 2>> $LOG_ERR
            fi
            echo "End Timestamp: `date +%s`" >> $LOG
            echo $END >> $LOG
            echo $END >> $LOG_ERR
        fi

        # If RNN was trained
        if [ -d "$OUTPUT/$MODEL/api-sequence/rnn/" ]; then
            echo "Evaluating model" >> $LOG
            echo "Evaluating model" >> $LOG_ERR
            echo "Start Timestamp: `date +%s`" >> $LOG
            # If there's a second file, then get the convert_classes file
            if [ "$OUTPUT/$MODEL/api-sequence/rnn/convert_classes.txt" != "" ]; then
                python3 evaluation.py "$OUTPUT/$MODEL/api-sequence/rnn/fold1-model.json" "$OUTPUT/$MODEL/api-sequence/rnn/fold1-weight.h5" "api-sequence-features/" "$INPUT/$CLASSES" "/app/label.txt" "$OUTPUT/prediction/api-sequence-rnn.csv" "$OUTPUT/$MODEL/api-sequence/rnn/convert_classes.txt" >> $LOG 2>> $LOG_ERR
            else
                python3 evaluation.py "$OUTPUT/$MODEL/api-sequence/rnn/fold1-model.json" "$OUTPUT/$MODEL/api-sequence/rnn/fold1-weight.h5" "api-sequence-features/" "$INPUT/$CLASSES" "/app/label.txt" "$OUTPUT/prediction/api-sequence-rnn.csv" >> $LOG 2>> $LOG_ERR
            fi
            echo "End Timestamp: `date +%s`" >> $LOG
            echo $END >> $LOG
            echo $END >> $LOG_ERR
        fi

        # If CNN was trained
        if [ -d "$OUTPUT/$MODEL/api-sequence/cnn/" ]; then
            echo "Evaluating model" >> $LOG
            echo "Evaluating model" >> $LOG_ERR
            echo "Start Timestamp: `date +%s`" >> $LOG
            # If there's a second file, then get the convert_classes file
            if [ "$OUTPUT/$MODEL/api-sequence/cnn/convert_classes.txt" != "" ]; then
                python3 evaluation.py "$OUTPUT/$MODEL/api-sequence/cnn/fold1-model.json" "$OUTPUT/$MODEL/api-sequence/cnn/fold1-weight.h5" "api-sequence-features/" "$INPUT/$CLASSES" "/app/label.txt" "$OUTPUT/prediction/api-sequence-cnn.csv" "$OUTPUT/$MODEL/api-sequence/cnn/convert_classes.txt" >> $LOG 2>> $LOG_ERR
            else
                python3 evaluation.py "$OUTPUT/$MODEL/api-sequence/cnn/fold1-model.json" "$OUTPUT/$MODEL/api-sequence/cnn/fold1-weight.h5" "api-sequence-features/" "$INPUT/$CLASSES" "/app/label.txt" "$OUTPUT/prediction/api-sequence-cnn.csv" >> $LOG 2>> $LOG_ERR
            fi
            echo "End Timestamp: `date +%s`" >> $LOG
            echo $END >> $LOG
            echo $END >> $LOG_ERR
        fi

        cd /app/
    fi

    # EXISTENCE
    if [ $( jq ".options.existence" "$CONFIG" ) = true ]; then
        cd /app/existence/

        # Extract features
        echo "Extracting features" >> $LOG
        echo "Extracting features" >> $LOG_ERR
        echo "Start Timestamp: `date +%s`" >> $LOG
        cd "$EXTRACT"
        python2.7 extract-existence.py "$RAW" "api.txt" "/app/label.txt" "$INPUT/$CLASSES" "/app/existence/api-existence.csv" >> $LOG 2>> $LOG_ERR
        cd ../..
        echo "End Timestamp: `date +%s`" >> $LOG
        echo $END >> $LOG
        echo $END >> $LOG_ERR

        # Evaluate model
        for model_fn in `ls -1 "$OUTPUT/$MODEL/api-existence/"`; do
            echo "Evaluating model" >> $LOG
            echo "Evaluating model" >> $LOG_ERR
            echo "Start Timestamp: `date +%s`" >> $LOG
            python3 evaluation.py "api-existence.csv" "/app/label.txt" "$OUTPUT/$MODEL/api-existence/$model_fn" "$OUTPUT/prediction/api-existence_${model_fn}.csv" >> $LOG 2>> $LOG_ERR
            echo "End Timestamp: `date +%s`" >> $LOG
            echo $END >> $LOG
            echo $END >> $LOG_ERR
        done

        cd /app/
    fi

    # FREQUENCY
    if [ $( jq ".options.frequency" "$CONFIG" ) = true ]; then
        cd /app/frequency/

        # Extract features
        echo "Extracting features" >> $LOG
        echo "Extracting features" >> $LOG_ERR
        echo "Start Timestamp: `date +%s`" >> $LOG
        cd "$EXTRACT"
        python2.7 extract-frequency.py "$RAW" "api.txt" "/app/label.txt" "$INPUT/$CLASSES" "/app/frequency/api-frequency.csv" >> $LOG 2>> $LOG_ERR
        cd ../..
        echo "End Timestamp: `date +%s`" >> $LOG
        echo $END >> $LOG
        echo $END >> $LOG_ERR

        # Evaluate model
        for model_fn in `ls -1 "$OUTPUT/$MODEL/api-frequency/"`; do
            echo "Evaluating model" >> $LOG
            echo "Evaluating model" >> $LOG_ERR
            echo "Start Timestamp: `date +%s`" >> $LOG
            python3 evaluation.py "api-frequency.csv" "/app/label.txt" "$OUTPUT/$MODEL/api-frequency/$model_fn" "$OUTPUT/prediction/api-frequency_${model_fn}.csv" >> $LOG 2>> $LOG_ERR
            echo "End Timestamp: `date +%s`" >> $LOG
            echo $END >> $LOG
            echo $END >> $LOG_ERR
        done

        cd /app/
    fi

    # ARGUMENTS
    if [ $( jq ".options.arguments" "$CONFIG" ) = true ]; then
        cd /app/arguments/

        mkdir -p "$OUTPUT/model/arguments"

        # Extract features
        echo "Extracting argument features" >> $LOG
        echo "Extracting argument features" >> $LOG_ERR
        echo "Start Timestamp: `date +%s`" >> $LOG
        cd extract_raw/
        python2.7 extract.py "$RAW" "$INPUT/$CLASSES" "/app/arguments/behavior_profiles/" >> $LOG 2>> $LOG_ERR
        python2.7 feature_set_to_minhash.py "/app/arguments/behavior_profiles/" "$INPUT/$CLASSES" "/app/arguments/behavior_profiles_minhash/" >> $LOG 2>> $LOG_ERR
        cd ../
        echo "End Timestamp: `date +%s`" >> $LOG
        echo $END >> $LOG
        echo $END >> $LOG_ERR

        cd ml_model/

        # Evaluate model
        for model_fn in `ls -1 "$OUTPUT/$MODEL/arguments/"`; do
            echo "Evaluating model" >> $LOG
            echo "Evaluating model" >> $LOG_ERR
            echo "Start Timestamp: `date +%s`" >> $LOG
            python2.7 evaluation.py "/app/arguments/behavior_profiles_minhash/" "$OUTPUT/$MODEL/arguments/$model_fn" "$INPUT/$CLASSES" "/app/label.txt" "$OUTPUT/prediction/arguments_${model_fn}.csv" >> $LOG 2>> $LOG_ERR
            echo "End Timestamp: `date +%s`" >> $LOG
            echo $END >> $LOG
            echo $END >> $LOG_ERR
        done

        cd /app/
    fi

    # Compress predictions and move them to output folder
    cd "$OUTPUT"
    zip -r "$OUTPUT/prediction.zip" "./prediction/"
    cd /app/

    # Copy model to output folder
    cp "$INPUT/$MODEL_ZIP" "$OUTPUT/$MODEL_ZIP"

    ls -l "$INPUT"

    # If logs exist in input, copy to output folder
    cp "$INPUT/"*.log*.txt "$OUTPUT/"
    LOG_IN=$(ls -1 "$INPUT/" | grep "\.log.*\.txt")
    LOG_IN=$(echo $LOG_IN | sed "s/\ /\",\"/g")

    NUM=$(ls -1 "$INPUT/" | grep "\.log.*\.txt" | wc -l)
    LOG_IN_FTYPE=$(yes "{\"ftype\":\"log\"}," | head -$NUM | tr -d '\n')

    if [ "$LOG_IN" = "" ]; then
        echo '{
        "name": "'"$NAME"'",
        "files": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'","prediction.zip"],
        "tags": [{"ftype":"log"},{"ftype":"log"},{"ftype":"prediction"}],
        "files_created": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'","prediction.zip"],
        "files_modified": []
        }' > "$OUTPUT/output.json"

    else
        echo '{
        "name": "'"$NAME"'",
        "files": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'","prediction.zip","'"$MODEL_ZIP"'","'"$LOG_IN"'"],
        "tags": [{"ftype":"log"},{"ftype":"log"},{"ftype":"prediction"},{"ftype":"model"},'"${LOG_IN_FTYPE:0:-1}"'],
        "files_created": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'","prediction.zip","'"$MODEL_ZIP"'"],
        "files_modified": ["'"$LOG_IN"'"]
        }' > "$OUTPUT/output.json"

    fi

fi


# Mimicry Attack
if [ "$NAME" = "Mimicry-Attack" ]; then
    # Get files
    CLASSES=$(parse_file "$CONFIG" ".benign.txt")
    MODEL_ZIP=$(parse_file "$CONFIG" ".model.zip")
    TARGET=$(parse_file "$CONFIG" ".target.txt")

    # Check input files
    if [ "$CLASSES" = "" ] || [ "$MODEL_ZIP" = "" ] || [ "$TARGET" = "" ]; then
        echo "Error. Couldn't find input files." >> $LOG_ERR
        exit_error "$NAME" "$LOG_NAME" "$LOG_ERR_NAME" "$OUTPUT"
    fi

    # Get model(s)
    OLD_NAME=$( zipinfo -1 "$INPUT/$MODEL_ZIP" | head -1 | awk '{split($NF,a,"/");print a[1]}' )
    MODEL="model"

    # Unzip models
    cd "$INPUT"
    unzip "$MODEL_ZIP" -d "$OUTPUT"
    cd "$OUTPUT"
    mv $OLD_NAME $MODEL
    cd /app/

    # Predictions folder which will get compressed and sent back to user
    mkdir "$OUTPUT/attack-prediction/"

    MIMICRY_CFG="/app/mimicry/mimicry.cfg"
    rm "$MIMICRY_CFG"

    echo "[input_options]" >> "$MIMICRY_CFG"
    echo "sequences=/app/sequence/api-sequences/" >> "$MIMICRY_CFG"
    echo "target_hashes=$INPUT/$TARGET" >> "$MIMICRY_CFG"
    echo "preferred=preferred.txt" >> "$MIMICRY_CFG"

    echo "[output_options]" >> "$MIMICRY_CFG"
    echo "attack_features=$OUTPUT/attack-feature/" >> "$MIMICRY_CFG"
    echo "attack_configs=$OUTPUT/attack-config/" >> "$MIMICRY_CFG"

    # Get sequence modeling type
    SEQUENCE_TYPE=$( jq -r ".options.sequence_type" "$CONFIG" )

    # Get ensemble options
    SEQUENCE_LSTM=false
    SEQUENCE_RNN=false
    SEQUENCE_CNN=false
    if [ $( jq ".options.sequence_lstm" "$CONFIG" ) = true ]; then
        SEQUENCE_LSTM=true
    fi
    if [ $( jq ".options.sequence_rnn" "$CONFIG" ) = true ]; then
        SEQUENCE_RNN=true
    fi
    if [ $( jq ".options.sequence_cnn" "$CONFIG" ) = true ]; then
        SEQUENCE_CNN=true
    fi

    # Folder where extraction code exists
    EXTRACT="/app/sequence/cuckoo-headless/extract_raw/"

    # SEQUENCE
    echo "[sequence]" >> "$MIMICRY_CFG"
    if [ $( jq ".options.sequence" "$CONFIG" ) = true ]; then
        echo "enable = true" >> "$MIMICRY_CFG"

        # Get generations
        GENERATIONS=$( jq ".options.generations" "$CONFIG" )
        echo "generations=$GENERATIONS" >> "$MIMICRY_CFG"

        # Default username/password for neo4j
        echo "neo4j_username=neo4j" >> "$MIMICRY_CFG"
        echo "neo4j_password='password'" >> "$MIMICRY_CFG"

        # Get sequence length
        SEQUENCE_WINDOW=$( jq ".options.sequence_window" "$CONFIG" )

        cd /app/sequence/
        # Extract sequences
        echo "Extracting sequences" >> $LOG
        echo "Extracting sequences" >> $LOG_ERR
        echo "Start Timestamp: `date +%s`" >> $LOG
        cd cuckoo-headless/extract_raw/
        python2.7 extract-sequence.py "$RAW" "$INPUT/$CLASSES" "/app/sequence/api-sequences/" >> $LOG 2>> $LOG_ERR
        python2.7 extract-sequence.py "$RAW" "$INPUT/$TARGET" "/app/sequence/api-sequences/" >> $LOG 2>> $LOG_ERR
        cd ../..
        echo "End Timestamp: `date +%s`" >> $LOG
        echo $END >> $LOG
        echo $END >> $LOG_ERR

        # Create benign Neo4j graph
        service neo4j restart
        sleep 5
        cd /app/mimicry
        cd sequence/
        python3 create-neo4j-csv.py "/app/sequence/api-sequences/" "$INPUT/$CLASSES" benign output.csv
        cp output.csv /var/lib/neo4j/import/mimicry.csv
        bash neo4j-load-csv.sh neo4j password
        cd /app

    else
        echo "enable = false" >> /app/mimicry/mimicry.cfg
    fi

    cd /app/mimicry/

    echo "Running Mimicry Attack" >> $LOG
    echo "Running Mimicry Attack" >> $LOG_ERR
    echo "Start Timestamp: `date +%s`" >> $LOG
    python3 mimicry.py "$MIMICRY_CFG"  >> $LOG 2>> $LOG_ERR
    cd ..
    echo "End Timestamp: `date +%s`" >> $LOG
    echo $END >> $LOG
    echo $END >> $LOG_ERR

    cd /app/sequence/

    # Create samples file
    rm "$OUTPUT/attack-feature/api-sequences-samples.txt"
    for fn in `find "$OUTPUT/attack-feature/api-sequences/" -mindepth 1 -maxdepth 1 -type f`; do
        # Get label for sample
        h=$(echo $fn | rev | cut -d'/' -f1 | rev)
        l=$(grep ${h:0:-2} "$INPUT/$TARGET" | cut -d$'\t' -f2)

        echo -e "${h}\t${l}" >> "$OUTPUT/attack-feature/api-sequences-samples.txt"
    done

    # Run evaluation on new features
    echo "Extracting sequence features" >> $LOG
    echo "Extracting sequence features" >> $LOG_ERR
    echo "Start Timestamp: `date +%s`" >> $LOG
    python3 preprocess.py "$OUTPUT/attack-feature/api-sequences/" "$EXTRACT/api.txt" "/app/label.txt" "$OUTPUT/attack-feature/api-sequences-samples.txt" "$OUTPUT/api-sequence-attack-features/" $SEQUENCE_WINDOW $SEQUENCE_TYPE >> $LOG 2>> $LOG_ERR
    echo "End Timestamp: `date +%s`" >> $LOG
    echo $END >> $LOG
    echo $END >> $LOG_ERR

    echo "Evaluating model" >> $LOG
    echo "Evaluating model" >> $LOG_ERR
    echo "Start Timestamp: `date +%s`" >> $LOG

    # LSTM model
    if [ $SEQUENCE_LSTM = true ]; then
        # If there's a second file, then get the convert_classes file
        if [ -f "$OUTPUT/$MODEL/api-sequence/lstm/convert_classes.txt" ]; then
            python3 evaluation.py "$OUTPUT/$MODEL/api-sequence/lstm/fold1-model.json" "$OUTPUT/$MODEL/api-sequence/lstm/fold1-weight.h5" "$OUTPUT/api-sequence-attack-features/" "$OUTPUT/attack-feature/api-sequences-samples.txt" "/app/label.txt" "$OUTPUT/attack-prediction/api-sequence-lstm.csv" "$OUTPUT/$MODEL/api-sequence/lstm/convert_classes.txt" >> $LOG 2>> $LOG_ERR
        else
            python3 evaluation.py "$OUTPUT/$MODEL/api-sequence/lstm/fold1-model.json" "$OUTPUT/$MODEL/api-sequence/lstm/fold1-weight.h5" "$OUTPUT/api-sequence-attack-features/" "$OUTPUT/attack-feature/api-sequences-samples.txt" "/app/label.txt" "$OUTPUT/attack-prediction/api-sequence-lstm.csv" >> $LOG 2>> $LOG_ERR
        fi
    fi

    # RNN model
    if [ $SEQUENCE_RNN = true ]; then
        # If there's a second file, then get the convert_classes file
        if [ -f "$OUTPUT/$MODEL/api-sequence/rnn/convert_classes.txt" ]; then
            python3 evaluation.py "$OUTPUT/$MODEL/api-sequence/rnn/fold1-model.json" "$OUTPUT/$MODEL/api-sequence/rnn/fold1-weight.h5" "$OUTPUT/api-sequence-attack-features/" "$OUTPUT/attack-feature/api-sequences-samples.txt" "/app/label.txt" "$OUTPUT/attack-prediction/api-sequence-rnn.csv" "$OUTPUT/$MODEL/api-sequence/rnn/convert_classes.txt" >> $LOG 2>> $LOG_ERR
        else
            python3 evaluation.py "$OUTPUT/$MODEL/api-sequence/rnn/fold1-model.json" "$OUTPUT/$MODEL/api-sequence/rnn/fold1-weight.h5" "$OUTPUT/api-sequence-attack-features/" "$OUTPUT/attack-feature/api-sequences-samples.txt" "/app/label.txt" "$OUTPUT/attack-prediction/api-sequence-rnn.csv" >> $LOG 2>> $LOG_ERR
        fi
    fi

    # CNN model
    if [ $SEQUENCE_CNN = true ]; then
        # If there's a second file, then get the convert_classes file
        if [ -f "$OUTPUT/$MODEL/api-sequence/cnn/convert_classes.txt" ]; then
            python3 evaluation.py "$OUTPUT/$MODEL/api-sequence/cnn/fold1-model.json" "$OUTPUT/$MODEL/api-sequence/cnn/fold1-weight.h5" "$OUTPUT/api-sequence-attack-features/" "$OUTPUT/attack-feature/api-sequences-samples.txt" "/app/label.txt" "$OUTPUT/attack-prediction/api-sequence-cnn.csv" "$OUTPUT/$MODEL/api-sequence/cnn/convert_classes.txt" >> $LOG 2>> $LOG_ERR
        else
            python3 evaluation.py "$OUTPUT/$MODEL/api-sequence/cnn/fold1-model.json" "$OUTPUT/$MODEL/api-sequence/cnn/fold1-weight.h5" "$OUTPUT/api-sequence-attack-features/" "$OUTPUT/attack-feature/api-sequences-samples.txt" "/app/label.txt" "$OUTPUT/attack-prediction/api-sequence-cnn.csv" >> $LOG 2>> $LOG_ERR
        fi
    fi

    echo "End Timestamp: `date +%s`" >> $LOG
    echo $END >> $LOG
    echo $END >> $LOG_ERR

    # Compress attack features and move them to output folder
    cd "$OUTPUT"
    zip -r "$OUTPUT/attack-feature.zip" "./attack-feature/"
    zip -r "$OUTPUT/attack-prediction.zip" "./attack-prediction/"
    zip -r "$OUTPUT/attack.cfg.zip" "./attack-config/"
    cd /app/

    # Write output.json
    echo '{
    "name": "'"$NAME"'",
    "files": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'","attack-feature.zip","attack-prediction.zip","attack.cfg.zip"],
    "tags": [{"ftype":"log"},{"ftype":"log"},{"ftype":"feature"},{"ftype":"prediction"},{"ftype":"cfg"}],
    "files_created": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'","attack-feature.zip","attack-prediction.zip","attack.cfg.zip"],
    "files_modified": []
    }' > "$OUTPUT/output.json"
fi


# PE Transformer
if [ "$NAME" = "PE-Transformer" ]; then
    # Get files
    CONFIG_ZIP=$(parse_file "$CONFIG" ".cfg.zip")

    # Check input files
    if [ "$CONFIG_ZIP" = "" ]; then
        echo "Error. Couldn't find input files." >> $LOG_ERR
        exit_error "$NAME" "$LOG_NAME" "$LOG_ERR_NAME" "$OUTPUT"
    fi

    # Get config(s)
    OLD_NAME=$( zipinfo -1 "$INPUT/$CONFIG_ZIP" | head -1 | awk '{split($NF,a,"/");print a[1]}' )
    CFG="cfg"

    # Get sample
    SAMPLE=$( jq -r ".options.hash" "$CONFIG" )

    #TODO - Only gets first config from api sequences attack. Should add flexibility in future.
    # Unzip config(s)
    cd "$INPUT"
    unzip "$CONFIG_ZIP" -d "$OUTPUT"
    cd "$OUTPUT"
    cp "$OLD_NAME/api-sequences/$SAMPLE/0.cfg" $CFG
    cd /app/

    cd /app/petransformer

    # Copy payloads
    mkdir -p ~/.msf4/modules/payloads/singles/windows/
    cp ./payloads/* ~/.msf4/modules/payloads/singles/windows/

    # Run transformer
    python3 main.py ./shellcode/ "$BINARY/$SAMPLE" "$OUTPUT/$CFG" "$OUTPUT/attack.exe" >> $LOG 2>> $LOG_ERR

    # Zip attack binary with password
    zip -P infected "$OUTPUT/attack.exe.zip" "$OUTPUT/attack.exe"

    # If logs exist in input, copy to output folder
    cp "$INPUT/"*.log*.txt "$OUTPUT/"
    LOG_IN=$(ls -1 "$INPUT/" | grep "\.log.*\.txt")
    LOG_IN=$(echo $LOG_IN | sed "s/\ /\",\"/g")

    NUM=$(ls -1 "$INPUT/" | grep "\.log.*\.txt" | wc -l)
    LOG_IN_FTYPE=$(yes "{\"ftype\":\"log\"}," | head -$NUM | tr -d '\n')

    # Write output.json
    if [ "$LOG_IN" = "" ]; then
        echo '{
        "name": "'"$NAME"'",
        "files": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'","attack.exe.zip"],
        "tags": [{"ftype":"log"},{"ftype":"log"},{"ftype":"zip"}],
        "files_created": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'","attack.exe.zip"],
        "files_modified": []
        }' > "$OUTPUT/output.json"

    else
        cp "$INPUT/$CONFIG_ZIP" "$OUTPUT"

        #TODO - assumes these two zip files will exist
        cp "$INPUT/attack-feature.zip" "$OUTPUT"
        cp "$INPUT/attack-prediction.zip" "$OUTPUT"

        echo '{
        "name": "'"$NAME"'",
        "files": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'","attack.exe.zip","'"$LOG_IN"'","attack-feature.zip","attack-prediction.zip","'"$CONFIG_ZIP"'"],
        "tags": [{"ftype":"log"},{"ftype":"log"},{"ftype":"zip"},'"${LOG_IN_FTYPE:0:-1}"',{"ftype":"feature"},{"ftype":"prediction"},{"ftype":"cfg"}],
        "files_created": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'","attack.exe.zip"],
        "files_modified": ["'"$LOG_IN"'","attack-feature.zip","attack-prediction.zip","'"$CONFIG_ZIP"'"]
        }' > "$OUTPUT/output.json"

    fi

fi

# Detect Trampoline
if [ "$NAME" = "Detect-Trampoline" ]; then
    # Get files
    NOMINAL=$(parse_file "$CONFIG" ".nominal.txt")
    TEST=$(parse_file "$CONFIG" ".test.txt")

    # Check input files
    if [ "$NOMINAL" = "" ]; then
        echo "Error. Couldn't find input files." >> $LOG_ERR
        exit_error "$NAME" "$LOG_NAME" "$LOG_ERR_NAME" "$OUTPUT"
    fi
    if [ "$TEST" = "" ]; then
        echo "Error. Couldn't find input files." >> $LOG_ERR
        exit_error "$NAME" "$LOG_NAME" "$LOG_ERR_NAME" "$OUTPUT"
    fi

    cd /app/petransformer/artifact/

    # Extract features from nominal and test sets
    python3 extract.py "$BINARY" "$INPUT/$NOMINAL" "$OUTPUT/nominal_features/"
    python3 extract.py "$BINARY" "$INPUT/$TEST" "$OUTPUT/test_features/"

    # Model nominal (unmodified) files
    python3 model_naive.py $OUTPUT/nominal_features/ "$INPUT/$NOMINAL" > "$OUTPUT/out.txt"
    threshold_num=`grep 'Average number of jumps:' "$OUTPUT/out.txt" | rev | cut -d ' ' -f 1 | rev`
    threshold_dist=`grep 'Average distance of jumps:' "$OUTPUT/out.txt" | rev | cut -d ' ' -f 1 | rev`
    threshold_ratio=`grep 'ratio' "$OUTPUT/out.txt" | rev | cut -d ' ' -f 1 | rev`

    # Run detection on test samples
    python3 eval.py "$OUTPUT/test_features/" "$INPUT/$TEST" \
                                             $threshold_num \
                                             $threshold_dist \
                                             $threshold_ratio >> $LOG 2>> $LOG_ERR

    # Write output.json
    echo '{
    "name": "'"$NAME"'",
    "files": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'"],
    "tags": [{"ftype":"log"},{"ftype":"log"}],
    "files_created": ["'"$LOG_NAME"'","'"$LOG_ERR_NAME"'"],
    "files_modified": []
}' > "$OUTPUT/output.json"
fi

echo "Finished: `date +%s`" >> $LOG
