{
    "type": "deepr.jobs.YarnLauncher",
    "config": {
        "type": "deepr.jobs.YarnLauncherConfig"
    },
    "run_on_yarn": "$run:run_on_yarn",
    "job": {
        "type": "deepr.jobs.Pipeline",
        "eval": null,
        "jobs": [
            {
                "type": "deepr.jobs.LogMetric",
                "key": "SUCCESS",
                "value": false,
                "use_mlflow": "$mlflow:use_mlflow"
            },
            {
                "type": "deepr.jobs.MLFlowSaveConfigs",
                "use_mlflow": "$mlflow:use_mlflow",
                "config": "@self",
                "macros": "@macros",
                "macros_eval": "@macros_eval",
                "formatter": {
                    "type": "deepr.jobs.MLFlowFormatter",
                    "include_keys": [
                        "path_model",
                        "path_dataset",
                        "eval_input_fn",
                        "exporters",
                        "initializer_fn",
                        "loss_fn",
                        "optimizer_fn",
                        "pred_fn",
                        "predict_input_fn",
                        "prepro_fn",
                        "train_input_fn",
                        "train_spec",
                        "eval_spec"
                    ]
                }
            },
            {
                "type": "deepr.jobs.YarnTrainer",
                "config": {
                    "type": "deepr.jobs.YarnTrainerConfig"
                },
                "train_on_yarn": "$run:train_on_yarn",
                "trainer": {
                    "type": "deepr.jobs.Trainer",
                    "eval": null,
                    "path_model": "$paths:path_model",
                    "pred_fn": {
                        "type": "deepr.examples.movielens.layers.VAEModel",
                        "vocab_size": 20108,
                        "dim": 600,
                        "dims_encode": [200],
                        "dims_decode": [600],
                        "keep_prob": 0.5,
                        "embeddings_name": "embeddings_in"
                    },
                    "loss_fn": {
                        "type": "deepr.examples.movielens.layers.MultiVAELoss",
                        "vocab_size": 20108,
                        "dim": 600,
                        "beta_start": 0,
                        "beta_end": 0.2,
                        "beta_steps": 20000,
                        "reg": null,
                        "embeddings_name": "embeddings",
                        "reuse_embeddings": false
                    },
                    "optimizer_fn": {
                        "type": "deepr.optimizers.TensorflowOptimizer",
                        "optimizer": "LazyAdam",
                        "learning_rate": 0.001
                    },
                    "train_input_fn": {
                        "type": "deepr.examples.movielens.readers.VAEReader",
                        "path_csv": "ml-20m/pro_sg/train.csv",
                        "vocab_size": 20108
                    },
                    "eval_input_fn": {
                        "type": "deepr.examples.movielens.readers.VAEReader",
                        "path_csv": "ml-20m/pro_sg/validation_tr.csv",
                        "vocab_size": 20108
                    },
                    "prepro_fn": {
                        "type": "deepr.examples.movielens.prepros.VAEPrepro",
                        "vocab_size": 20108,
                        "buffer_size": 1024,
                        "batch_size": 512,
                        "repeat_size": null,
                        "prefetch_size": 1,
                        "num_parallel_calls": 8
                    },
                    "exporters": [
                        {
                            "type": "deepr.exporters.BestCheckpoint",
                            "metric": "loss",
                            "mode": "decrease"
                        },
                        {
                            "type": "deepr.exporters.SaveVariables",
                            "path_variables": "$paths:path_variables",
                            "variable_names": [
                                "biases",
                                "embeddings"
                            ]
                        },
                        {
                            "type": "deepr.exporters.SavedModel",
                            "path_saved_model": "$paths:path_saved_model",
                            "fields": [
                                {
                                    "type": "deepr.utils.Field",
                                    "name": "inputPositives",
                                    "shape": [null],
                                    "dtype": "int64"
                                },
                                {
                                    "type": "deepr.utils.Field",
                                    "name": "inputMask",
                                    "shape": [null],
                                    "dtype": "bool"
                                }
                            ]
                        }
                    ],
                    "train_metrics": [
                        {
                            "type": "deepr.metrics.StepCounter",
                            "name": "num_steps"
                        },
                        {
                            "type": "deepr.metrics.DecayMean",
                            "decay": 0.98,
                            "pattern": "loss*",
                            "tensors": ["beta"]
                        }
                    ],
                    "eval_metrics": [
                        {
                            "type": "deepr.metrics.Mean",
                            "pattern": "loss*"
                        }
                    ],
                    "final_metrics": [
                        {
                            "type": "deepr.metrics.Mean",
                            "pattern": "loss*"
                        }
                    ],
                    "train_hooks": [
                        {
                            "type": "deepr.hooks.LoggingTensorHookFactory",
                            "functions": {
                                "memory_gb": {
                                    "type": "deepr.hooks.ResidentMemory",
                                    "unit": "gb"
                                },
                                "max_memory_gb": {
                                    "type": "deepr.hooks.MaxResidentMemory",
                                    "unit": "gb"
                                }
                            },
                            "name": "training",
                            "skip_after_step": "$params:max_steps",
                            "every_n_iter": 100,
                            "use_mlflow": "$mlflow:use_mlflow"
                        },
                        {
                            "type": "deepr.hooks.SummarySaverHookFactory",
                            "save_steps": 100
                        },
                        {
                            "type": "deepr.hooks.NumParamsHook",
                            "use_mlflow": "$mlflow:use_mlflow"
                        },
                        {
                            "type": "deepr.hooks.LogVariablesInitHook"
                        },
                        {
                            "type": "deepr.hooks.StepsPerSecHook",
                            "batch_size": 512,
                            "name": "training",
                            "use_mlflow": "$mlflow:use_mlflow",
                            "skip_after_step": 100000
                        },
                        {
                            "type": "deepr.hooks.EarlyStoppingHookFactory",
                            "metric": "loss",
                            "max_steps_without_improvement": 1000,
                            "min_steps": 5000,
                            "mode": "decrease",
                            "run_every_steps": 100,
                            "final_step": 100000
                        }
                    ],
                    "eval_hooks": [
                        {
                            "type": "deepr.hooks.LoggingTensorHookFactory",
                            "name": "validation",
                            "at_end": true,
                            "use_mlflow": "$mlflow:use_mlflow"
                        }
                    ],
                    "final_hooks": [
                        {
                            "type": "deepr.hooks.LoggingTensorHookFactory",
                            "name": "final_validation",
                            "at_end": true,
                            "use_mlflow": "$mlflow:use_mlflow"
                        }
                    ],
                    "train_spec": {
                        "max_steps": "$params:max_steps"
                    },
                    "eval_spec": {
                        "steps": null,
                        "start_delay_secs": 30,
                        "throttle_secs": 30
                    },
                    "final_spec": {
                        "steps": null
                    },
                    "run_config": {
                        "type": "deepr.jobs.RunConfig",
                        "save_checkpoints_steps": 300,
                        "save_summary_steps": 300,
                        "keep_checkpoint_max": null,
                        "log_step_count_steps": 100
                    },
                    "config_proto": {
                        "type": "deepr.jobs.ConfigProto",
                        "inter_op_parallelism_threads": 8,
                        "intra_op_parallelism_threads": 8,
                        "log_device_placement": false,
                        "gpu_device_count": 0,
                        "cpu_device_count": 48
                    }
                }
            },
            {
                "type": "deepr.examples.movielens.jobs.Predict",
                "path_saved_model": "$paths:path_saved_model",
                "path_predictions": "$paths:path_predictions",
                "input_fn": {
                    "type": "deepr.examples.movielens.readers.TestVAEReader",
                    "path_csv_tr": "ml-20m/pro_sg/test_tr.csv",
                    "path_csv_te": "ml-20m/pro_sg/test_te.csv",
                    "vocab_size": 20108
                },
                "prepro_fn": {
                    "type": "deepr.examples.movielens.prepros.VAEPrepro",
                    "vocab_size": 20108,
                    "buffer_size": 1024,
                    "batch_size": 512,
                    "repeat_size": null,
                    "prefetch_size": 1,
                    "num_parallel_calls": 8,
                    "test": true
                },
            },
            {
                "type": "deepr.examples.movielens.jobs.Evaluate",
                "path_predictions": "$paths:path_predictions",
                "path_embeddings": "$paths:path_embeddings",
                "path_biases": "$paths:path_biases",
                "k": 20,
                "use_mlflow": "$mlflow:use_mlflow"
            },
            {
                "type": "deepr.examples.movielens.jobs.Evaluate",
                "path_predictions": "$paths:path_predictions",
                "path_embeddings": "$paths:path_embeddings",
                "path_biases": "$paths:path_biases",
                "k": 50,
                "use_mlflow": "$mlflow:use_mlflow"
            },
            {
                "type": "deepr.jobs.LogMetric",
                "key": "SUCCESS",
                "value": true,
                "use_mlflow": "$mlflow:use_mlflow"
            },
            {
                "type": "deepr.jobs.CleanupCheckpoints",
                "path_model": "$paths:path_model"
            }
        ]
    }
}