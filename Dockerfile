FROM tarantool/tarantool:1
COPY . /opt/tarantool/
EXPOSE 3301
WORKDIR /opt/tarantool/
CMD [ "./start.sh" ]