compile_db:
	gcc src/main.c -o db.out

test:
	bundle exec rspec
