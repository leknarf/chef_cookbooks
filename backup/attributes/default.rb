default[:backup][:backup_user] = 'backup_user'

default[:backup][:name] = "postgres_backup"
default[:backup][:description] = "Postgres backup"

default[:backup][:s3][:bucket_region] = 'us-east-1'

# Create this beforehand
default[:backup][:s3][:keep] = '10'

default[:backup][:s3][:sync_path] = "/files"

# List directories which you want to sync.
default[:backup][:s3][:sync_directories] = ["/tmp"]

default[:backup][:mail][:on_success] = true
default[:backup][:mail][:on_failure] = true
