# ビルドステージ
FROM ubuntu:focal AS build

# 必要なパッケージのインストール
RUN apt update && DEBIAN_FRONTEND=noninteractive apt -y install \
    wget unzip tar python3-pip python3-dev g++ libsndfile1-dev libasound2-dev libatlas-base-dev libjack-jackd2-dev

# pipとCythonのアップグレード
RUN pip install --upgrade pip && pip install Cython==0.29.23

# VOICEVOXのコアとONNX Runtimeのダウンロードと設定
RUN mkdir -p /voicevox_engine && \
    wget https://github.com/VOICEVOX/voicevox_core/releases/download/0.11.4/core.zip && \
    unzip core.zip && \
    mv core /voicevox_engine && \
    wget https://github.com/VOICEVOX/onnxruntime-builder/releases/download/1.10.0.1/onnxruntime-linux-arm64-cpu-v1.10.0.tgz && \
    tar xzvf onnxruntime-linux-arm64-cpu-v1.10.0.tgz && \
    mv onnxruntime-linux-arm64-cpu-v1.10.0 /voicevox_engine

# 最終ステージ
FROM ubuntu:focal

# 必要なパッケージのインストール
RUN apt update && DEBIAN_FRONTEND=noninteractive apt -y install \
    git python3 python3-dev python3-wheel cmake g++ libsndfile1

# pipとCythonのアップグレード
RUN pip install --upgrade pip && pip install Cython==0.29.23

# VOICEVOXエンジンのクローン
RUN git clone -b 0.11.4 https://github.com/VOICEVOX/voicevox_engine.git && \
    cd voicevox_engine/ && \
    pip install -r requirements.txt -r requirements-test.txt

# ビルドステージからのファイルコピー
COPY --from=build /voicevox_engine /voicevox_engine

# 環境変数の設定
ENV VV_CPU_NUM_THREADS=4

# コンテナ起動時のコマンド
CMD ["python3","/voicevox_engine/run.py","--voicelib_dir","/voicevox_engine/core","--runtime_dir","/voicevox_engine/onnxruntime-linux-arm64-cpu-v1.10.0/lib","--host","0.0.0.0"]
