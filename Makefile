REBAR = ./rebar
# RELX  = ./relx

# @TODO FIXME: This doesn't work with the default `make` program on FreeBSD.
OTPREL = $(shell erl -noshell -eval 'io:format(erlang:system_info(otp_release)), halt().')

PLT = $(HOME)/.dialyzer_plt.$(OTPREL)
ERLDIRS = ./include ./src ./test

DIALYZER_OPTS ?= -Wunmatched_returns -Werror_handling -Wunderspecs
DIALYZER_NOSPEC_OPTS ?= -Wno_undefined_callbacks

dialyzer=dialyzer -q --src --plt $(PLT) $(DIALYZER_OPTS) -r $(ERLDIRS)
dialyzer-nospec=dialyzer -q --src --plt $(PLT) --no_spec $(DIALYZER_NOSPEC_OPTS) -r $(ERLDIRS)

.PHONY: all deps compile test build-plt dialyze dialyze-nospec clean run

all: get-deps update-deps compile test

test: eunit

get-deps:
	@( $(REBAR) get-deps )

update-deps:
	@( $(REBAR) update-deps )

compile:
	@( $(REBAR) compile )

compile-for-eunit:
	@( $(REBAR) compile -r eunit compile_only=true skip_apps='meck,ubf,ubf_thrift,thrift' )

eunit: compile-for-eunit
	@( $(REBAR) eunit -r skip_apps='ubf,gdss_ubf_proto,ubf_thrift,thrift,lager,meck,asciiedoc,edown' )

build-plt: $(PLT)

dialyze: build-plt clean compile
	@( echo "dialyzing w/spec: $(RELPKG) ..." )
	-$(dialyzer)
# @TODO   -$(dialyzer) | grep -v '^ *$$' | tee $(DIALYZE_IGNORE_WARN).log | fgrep -v -f $(DIALYZE_IGNORE_WARN)

dialyze-nospec: build-plt clean compile
	@( echo "dialyzing w/o spec: $(RELPKG) ..." )
	-$(dialyzer-nospec)
# @TODO	-$(dialyzer-nospec) | grep -v '^ *$$' | tee $(DIALYZE_NOSPEC_IGNORE_WARN).log | fgrep -v -f $(DIALYZE_NOSPEC_IGNORE_WARN)

# rel: deps compile
# 	@( rm -rf ../rel/embedded_hibari )
#	@( $(RELX) -o ../rel tar )

clean:
	@( $(REBAR) clean -r )
	@( rm -rf ./hibari )
	@( rm -f ./Schema.local )

run:
	@( mkdir -p hibari/log hibari/data hibari/root )
	@( cp -rp deps/gdss_admin/priv/root/htdocs hibari/root/)
	@( erl -pa ebin deps/*/ebin -name 'emb-hibari@127.0.0.1' \
	       -config rel/files/sys.config -s eh_app manual_start )

$(PLT):
	@echo "building: $(PLT) ..."
	-dialyzer -q --build_plt --output_plt $(PLT) --apps \
		asn1 \
		compiler \
		crypto \
		dialyzer \
		diameter \
		edoc \
		erts \
		et \
		eunit \
		gs \
		hipe \
		inets \
		kernel \
		mnesia \
		observer \
		parsetools \
		public_key \
		runtime_tools \
		sasl \
		ssl \
		stdlib \
		syntax_tools \
		tools \
		webtool \
		xmerl
