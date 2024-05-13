# Storage Node và DA service

Hệ thống 0G bao gồm nhiều thành phần, mỗi thành phần có chức năng riêng. Các bước chi tiết được cung cấp làm kim chỉ nam để triển khai toàn bộ và hoàn thiện hệ thống.

# Điều kiện tiên quyết
Các dịch vụ lưu trữ và DA 0G tương tác với các hợp đồng trên chuỗi để xác nhận gốc blob và khai thác PoRA.

Contract trên môi trường testnet hiện tại:

- Flow Contract: `0x22C1CaF8cbb671F220789184fda68BfD7eaA2eE1`

- Mine Contract: `0x8B9221eE2287aFBb34A7a1Ef72eB00fdD853FFC2`

Lưu ý, tutorial này sử dụng trên môi trường Linux, cụ thể là Ubuntu 22.04 LTS

# Storage node
Bước đầu tiên là triển khai nút lưu trữ. Là một hệ thống lưu trữ phân tán, hệ thống có thể có nhiều phiên bản.

1. Cài đặt dependencies
```
sudo apt-get update
sudo apt-get install clang cmake build-essential
```

2. Cài đặt rustup
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

3. Cài đặt Go
```
# Download the Go installer
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz

# Extract the archive
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz

# Add /usr/local/go/bin to the PATH environment variable by adding the following line to your ~/.profile.
export PATH=$PATH:/usr/local/go/bin
```

4. Sau đó tải xuống source code của node
```
git clone https://github.com/0glabs/0g-storage-node.git
```

5. Build từ source code
```
cd 0g-storage-node
git submodule update --init

# Build in release mode
cargo build --release
```

6. Cập nhật file `run/config.toml` như sau:
```
# p2p port
network_libp2p_port

# rpc endpoint
rpc_listen_address

# peer nodes, we provided two nodes, you can also modify to your own ips
network_boot_nodes = ["/ip4/54.219.26.22/udp/1234/p2p/16Uiu2HAmPxGNWu9eVAQPJww79J32pTJLKGcpjRMb4Qb8xxKkyuG1","/ip4/52.52.127.117/udp/1234/p2p/16Uiu2HAm93Hd5azfhkGBbkx1zero3nYHvfjQYM2NtiW4R3r5bE2g"]

# flow contract address
log_contract_address

# mine contract address
mine_contract_address

# layer one blockchain rpc endpoint
blockchain_rpc_endpoint

# block number to start the sync
log_sync_start_block_number

# location for db, network logs
db_dir
network_dir

# set these two fields if you want to become a miner
# your miner id, can be arbitrary hex string with 64 length
# do not include leading 0x
# need to set a unique id, otherwise it will raise error when you send reward tx
miner_id
# your private key with 64 length
# do not include leading 0x
# do not omit leading 0
miner_key
```

7. Chạy service
Mở `tmux` để chạy nền

```
tmux
cd run
# consider using tmux in order to run in background
../target/release/zgs_node --config config.toml
```

# KV storage

Bước thứ hai là khởi động dịch vụ KV.
1. Cài đặt dependencies và rust tương tự ở phần Storage Node phía trên

1. Tải xuống mã nguồn
```
git clone https://github.com/0glabs/0g-storage-kv.git
```

2. Build mã nguồn

```
cd 0g-storage-kv
git submodule update --init

# Build in release mode
cargo build --release
```

3. Copy config_example.toml thành config.toml và cập nhật các tham số.
```
# rpc endpoint
rpc_listen_address
# ips of storage service, separated by ","
zgs_node_urls = "http://ip1:port1,http://ip2:port2,..."

# layer one blockchain rpc endpoint
blockchain_rpc_endpoint

# flow contract address
log_contract_address

# block number to start the sync, better to align with the config in storage service
log_sync_start_block_number
```

4. Chạy dịch vụ kv
Chạy trong `tmux` để dịch vụ chạy nền

```
tmux
cd run

# consider using tmux in order to run in background
../target/release/zgs_kv --config config.toml
```
Lưu ý: Cấu hình hệ thống được đề xuất giống như Storage Node.

# Data Availability Service
Bước tiếp theo là bắt đầu dịch vụ 0GDA, đây là dịch vụ chính để gửi các yêu cầu đến.

1. Cài đặt dependencies, go và rust tương tự ở phần Storage Node

2. Tải source code
```
git clone https://github.com/0glabs/0g-data-avail.git
```
## Dịch vụ phân tán
3. Update file `0g-data-avail/disperser/Makefile`

- For encoder
```
# grpc port
--disperser-encoder.grpc-port 34000

# metric port
--disperser-encoder.metrics-http-port 9109

# number of workers, can be determined by the number of cores
--kzg.num-workers

# max concurrent request
--disperser-encoder.max-concurrent-requests

# size of request pool, can be larger than the number of cores
--disperser-encoder.request-pool-size
```

- For batcher
```
# layer one blockchain rpc endpoint
--chain.rpc

# private key of wallet account, can also set as environment variable
--chain.private-key

# modify the gas limit for different chains
--chain.gas-limit

# batch size limit, can be a relative large number like 1000
--batcher.batch-size-limit

# number of segments to upload in single rpc request
--batcher.storage.upload-task-size

# interval for disperse finality
--batcher.finalizer-interval

# aws configs, can be set into environment variables as well
--batcher.aws.region
--batcher.aws.access-key-id
--batcher.aws.secret-access-key
--batcher.s3-bucket-name
--batcher.dynamodb-table-name

# endpoints of storage services, for multiple endpoints, separate them one by one
--batcher.storage.node-url
--batcher.storage.node-url

# endpoint of kv service
--batcher.storage.kv-url

# flow contract address
--batcher.storage.flow-contract

# timeout for encoding, set based on the instance capacitgy
--encoding-timeout 10s
```

- For disperser
```
# port to listen on the requests
--disperser-server.grpc-port

# aws configs, can be set into environment variables as well
# note the keys are different from which in batcher
--disperser-server.aws.region
--disperser-server.aws.access-key-id
--disperser-server.aws.secret-access-key
--disperser-server.s3-bucket-name
--disperser-server.dynamodb-table-name
```

4. Build the source code
```
cd 0g-data-avail/disperser
make build
```

5. Chạy encoder, batcher và disperser
```
# encoder
make run_encoder

# batcher
make run_batcher

# disperser
make run_server
```

Cập nhật: Bây giờ bạn có thể xây dựng và chạy máy chủ với một dịch vụ kết hợp.
```
make run_combined
```
Lưu ý rằng cấu hình cho máy chủ kết hợp giống như các máy chủ riêng biệt ngoại trừ việc tiền tố của một số tham số được thiết lập thành combined-server. Vui lòng tham khảo tệp Makefile để biết các cấu hình chi tiết.
Bây giờ chúng tôi cũng cung cấp một tùy chọn để sử dụng bộ nhớ làm cơ sở dữ liệu metadata thay vì aws dynamodb. Đặt --combined-server.use-memory-db để chỉ định cơ sở dữ liệu bạn muốn sử dụng.

## Dịch vụ truy xuất

6. Update file `0g-data-avail/retriever/Makefile`

```
# grpc port to listen on requests
--retriever.grpc-port

# endpoints of storage services
--retriever.storage.node-url
--retriever.storage.node-url

# endpoint of kv service
--retriever.storage.kv-url

# flow contract addres
--retriever.storage.flow-contract
```

7. Build the source code
```
cd 0g-data-avail/retriever
make build
```

8. Run retriever
```
make run
```
Lưu ý: Bạn có thể triển khai tất cả các dịch vụ này trên một máy chủ. Encoder sẽ là điểm nghẽn vì nó đòi hỏi nhiều tính toán CPU. Do đó, số lõi CPU tuyến tính liên quan đến hiệu suất (Mbps). Đề xuất có ít nhất 32 lõi CPU cho dịch vụ của bạn. (loại `c6i.8xlarge` nếu bạn muốn triển khai trên AWS). 

Ngoài ra, việc triển khai nút lưu trữ, kv và dịch vụ da trong cùng một khu vực có thể tăng thông lượng. Đã được thử nghiệm trên AWS, với loại mẫu lưu trữ `m7i.xlarge` và loại `c6i.12xlarge` cho dịch vụ DA, thông lượng có thể đạt 15 Mbps.

# Storage Node CLI
0G đã cũng cấp một CLI tool để bạn có thể tương tác trực tiếp với storage node.

1. Download the source code
```
git clone https://github.com/0glabs/0g-storage-client.git
```

2. Build the source code
```
cd 0g-storage-client
go build
```

3. Lệnh về file upload/download
```
# file upload
./0g-storage-client upload --url <blockchain_rpc_endpoint> --contract <0g-storage_contract_address> --key <private_key> --node <storage_node_rpc_endpoint> --file <file_path>
# file download
./0g-storage-client download --node <storage_node_rpc_endpoint> --root <file_root_hash> --file <output_file_path>
```

Lấy contract address tại phần đầu tiên của hướng dẫn

Đối với RPC endpoint của storage node, bạn có thể sử dụng https://rpc-storage-testnet.0g.ai đã triển khai bởi dự án. Hoặc bạn có thể tự triển khai bằng cách thực hiện theo các hướng dẫn ở trên.

# Integration Test
Nếu bạn muốn thực hiện các bài kiểm tra tích hợp trên toàn bộ dịch vụ DA, bạn có thể sử dụng [công cụ đánh giá](https://github.com/0glabs/0g-da-example-rust) mà 0G đã cung cấp.

1. Cài đặt extra dependency
```
sudo apt-get install protobuf-compiler
```

2. Download the source code
```
git clone https://github.com/0glabs/0g-da-example-rust.git
```

3. Build the source code
```
cd 0g-da-example-rust
cargo build
```

4. Run the test
```
cargo run -- zgda-disperse --rps <int> --max-out-standing <int> --url <endpoint> --block-size <int> --chunk-size <int> --target-chunk-num <int>
```

**Lưu ý:**

- `rps` và `max-out-standing` được thiết lập để điều khiển tốc độ của các yêu cầu
- `url` là điểm cuối của dịch vụ phân tán ở Dịch vụ phân tán
- `block-size` là kích thước của tổng số dữ liệu tính bằng byte
- `chunk-size` tương đương với kích thước blob tính bằng byte của mỗi yêu cầu được gửi đến dịch vụ phân tán
- `target-chunk-num` là số lượng các phần được định nghĩa trong dịch vụ 0GDA. Nó được sử dụng để chia blob thành số lượng phần tương ứng. Nó được giới hạn cứng bởi kích thước của blob.
