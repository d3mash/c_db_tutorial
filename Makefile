compile_db:
	gcc src/main.c -o db.out

test:
	bundle exec rspec

run:
	./db.out db_data_file
