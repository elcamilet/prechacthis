
main_page(Request) :-
	http_main_page_path(MainPagePath),
	get_cookie(main_persons, Request, CookiePersons, 2),	
	get_cookie(main_max, Request, CookieMax, 4),
	get_cookie(main_passesmin, Request, CookiePassesMin, 1),
	get_cookie(main_passesmax, Request, CookiePassesMax, -1),
	get_cookie(main_results, Request, CookieResults, 42),
	
	a2Number(CookiePersons, CookiePersonsInt),
	a2Number(CookieMax, CookieMaxInt),
	a2Number(CookiePassesMin, CookiePassesMinInt),
	a2Number(CookiePassesMax, CookiePassesMaxInt),
	a2Number(CookieResults, CookieResultsInt),
	
	http_parameters(
		Request,
		[ 
			persons(ReqPersons, [integer, default(CookiePersonsInt)]),
			objects(ReqObjects, [default('')]),
			period(ReqPeriod, [default('')]),
			max(ReqMax, [integer, default(CookieMaxInt)]),
			passesmin(ReqPassesMin, [integer, default(CookiePassesMinInt)]),
			passesmax(ReqPassesMax, [integer, default(CookiePassesMaxInt)]),
			contain(ReqContain, [default('')]),
			exclude(ReqExclude, [default('')]),
			clubdoes(ReqClubDoes, [default('')]),
			react(ReqReact, [default('')]),
			magic(ReqMagic, [integer, default(0)]),
			results(ReqResults, [integer, default(CookieResultsInt)]),
			debug(Debug, [default('off')]),
			infopage(GoToInfoPage, [default('true')])
		]
	),
	
	retractall(href_type(_)),
	asserta(href_type(html)),
	
	set_cookie(main_persons, ReqPersons),
	set_cookie(main_max, ReqMax),
	set_cookie(main_passesmin, ReqPassesMin),
	set_cookie(main_passesmax, ReqPassesMax),
	set_cookie(main_results, ReqResults),
	
	(Debug = on -> DebugHTML = pre([],[\[Request]]); DebugHTML = ''),
	
	(a2Number(ReqPassesMax, -1) -> ReqPassesMaxVar = _Var; ReqPassesMaxVar = ReqPassesMax),
	(
		(
			memberchk(path(MainPagePath), Request),
			find_siteswap_lists(
				SiteswapLists,
				ReqPersons,
				ReqObjects,
				ReqPeriod,
				ReqMax,
				ReqPassesMin,
				ReqPassesMaxVar,
				ReqContain,
				ReqExclude,
				ReqClubDoes,
				ReqReact,
				ReqMagic,
				ReqResults
			)
		);
		SiteswapLists = false
	),
	(
		(
			GoToInfoPage = true,
			SiteswapLists = [SiteswapList], 
			memberchk(siteswaps(Siteswaps), SiteswapList),
			Siteswaps = [Pattern]
		) -> 
		(
			memberchk(search(BackURLSearchList), Request),
			parse_url_search(BackURLSearch, BackURLSearchList),
			format(atom(BackURL), '.~w?~s&infopage=false', [MainPagePath, BackURLSearch]),
			infoPage_html_page(Pattern, ReqPersons, [], BackURL, Request)
		) ;
		(
			html_set_options([
					dialect(html), 
					doctype('HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd"'),
					content_type('text/html; charset=UTF-8')
			]),
			reply_html_page(
				[
					title('PrechacThis'),
					meta(['http-equiv'('Content-Type'), content('text/html;charset=utf-8')]),
					link([type('text/css'), rel('stylesheet'), href('./css/prechacthis.css')]),
					link([rel('shortcut icon'), href('./images/favicon.png')])
					%\ajax_script
				],
				[
					DebugHTML,
					\mainPage_all_lists_of_siteswaps(
						SiteswapLists, 
						Request, 
						ReqPersons
					),
					\mainPage_form(
						MainPagePath,
						ReqPersons, 
						ReqObjects, 
						ReqPeriod, 
						ReqMax, 
						ReqPassesMin, 
						ReqPassesMax, 
						ReqContain, 
						ReqExclude, 
						ReqClubDoes, 
						ReqReact, 
						ReqMagic, 
						ReqResults
					)
				]
			)
		)	
	).
	
	

find_siteswap_lists(SiteswapLists, PersonsInt, ObjectsAtom, LengthAtom, MaxInt, PassesMinInt, PassesMaxInt, ContainAtom, DontContainAtom, ClubDoesAtom, ReactAtom, MagicInt, ResultsInt) :-
	name(ContainAtom, ContainList),
	name(DontContainAtom, DontContainList),
	name(ClubDoesAtom, ClubDoesList),
	name(ReactAtom, ReactList),
	findall(
		Siteswaps,
		(
			preprocess_number(ObjectsAtom, ObjectsInt),
			preprocess_number(LengthAtom, LengthInt),
			find_siteswaps(Siteswaps, PersonsInt, ObjectsInt, LengthInt, MaxInt, PassesMinInt, PassesMaxInt, ContainList, DontContainList, ClubDoesList, ReactList, MagicInt, ResultsInt)
		),
		SiteswapLists
	).


find_siteswaps(SiteswapList, Persons, Objects, Length, Max, PassesMin, PassesMax, Contain, DontContain, ClubDoes, React, Magic, Results) :-
	get_time(Start),
	findAtMostNUnique(Throws, 
		siteswap(Throws, Persons, Objects, Length, Max, PassesMin, PassesMax, Contain, DontContain, ClubDoes, React, Magic),
		Results,
		1,
		Bag,
		Flag
	),
	length(Bag, NumberOfSiteswaps),
	NumberOfSiteswaps > 0, !,
	sortListOfSiteswaps(Bag, Siteswaps),
	get_time(End),
	Time is End - Start,
	SiteswapList = [
		flag(Flag),
		time(Time),
		objects(Objects), 
		length(Length),
		siteswaps(Siteswaps)
	].



mainPage_all_lists_of_siteswaps(SiteswapLists, Request, Persons) -->
	{
		
		http_main_page_path(MainPagePath),
		memberchk(path(MainPagePath), Request)
	},
	html(
		table([align(center), cellpadding(0)],[
			tr([],[
				td([],[
					h2([],[
						Persons,
						' Jugglers'
					]),
					\mainPage_walk_list_of_siteswapLists(SiteswapLists, Request, Persons)
				])
			])
		])
	).
mainPage_all_lists_of_siteswaps(_Siteswaps, _Request, _Persons) -->
	[].		

mainPage_walk_list_of_siteswapLists([], _Request, _Persons) --> [], !.
mainPage_walk_list_of_siteswapLists([SiteswapList|Rest], Request, Persons) -->
	{
		memberchk(path(MainPagePath), Request),!,
		memberchk(flag(Flag), SiteswapList),
		memberchk(time(Time), SiteswapList),
		memberchk(objects(Objects), SiteswapList),
		memberchk(length(Length), SiteswapList),
		memberchk(siteswaps(Siteswaps), SiteswapList),
		length(Siteswaps, NumberOfResults),
		(Flag = some -> 
			HowMany = p([class(some)],['Just a selection of patterns is shown!']);
			(Flag = time ->
				HowMany = p([class(some)],['Time is over, that\'s what has been found!']);
				(NumberOfResults is 1 ->	
					HowMany = p([class(all)],['The only possible pattern has been found!']);
					HowMany = p([class(all)],['All ', NumberOfResults, ' patterns have been found!'])
				)	
			)	
		),
		memberchk(search(BackURLSearchList), Request),
		parse_url_search(BackURLSearch, BackURLSearchList),
		format(atom(BackURL), ".~w?~s", [MainPagePath, BackURLSearch])
	},
	html(
		div([class(inline)],[
			div([class(swaps)],[
				h3([],[
					Objects, 
					' objects, period ', 
					Length
				]),
				HowMany,
				p([class(time)],['(', Time, ' seconds)']),
				\mainPage_list_of_siteswaps(Siteswaps, Persons, BackURL)
			])
		])
	),
	mainPage_walk_list_of_siteswapLists(Rest, Request, Persons).
	

mainPage_list_of_siteswaps([], _Persons, _BackURL) -->
	[],!.
mainPage_list_of_siteswaps([Siteswap|Siteswaps], Persons, BackURL) -->	
	mainPage_siteswap_link(Siteswap, Persons, BackURL),
	mainPage_list_of_siteswaps(Siteswaps, Persons, BackURL).

mainPage_siteswap_link(Throws, Persons, BackURL) -->
	{
		length(Throws, Length),
		float_to_shortpass(Throws, ThrowsShort),
		magicPositions(Throws, Persons, MagicPositions)
	},	
	html([
		p([],[
			\html_href(ThrowsShort, Persons, [], BackURL, [], \mainPage_siteswap(ThrowsShort, Length, Persons, MagicPositions))
		])
	]).
    %convertP(Throws, ThrowsP, Length, Persons),
	%convertMagic(ThrowsP, MagicPositions, ThrowsPM),
	%convertMultiplex(ThrowsPM,ThrowsPMM),
    %writeSwap(ThrowsPMM, Throws, Persons, BackURL).

mainPage_siteswap([], _Length, _Persons, _MagicPositions) --> [],!.
mainPage_siteswap([Throw], Length, Persons, MagicPositions) -->
	{
		Position is Length - 1, !
	},
	html_throw(Throw, [hideIndex(Persons), colorThrow(Length), magic(Position, MagicPositions)]).
mainPage_siteswap([Throw|RestThrows], Length, Persons, MagicPositions) -->
	{
		length(RestThrows, RestLength),
		Position is Length - RestLength - 1
	},
	html_throw(Throw, [hideIndex(Persons), colorThrow(Length), magic(Position, MagicPositions)]),
	html(&(nbsp)),
	mainPage_siteswap(RestThrows, Length, Persons, MagicPositions).



	
mainPage_form(MainPagePath, Persons, Objects, Period, Max, PassesMin, PassesMax, Contain, Exclude, ClubDoes, React, Magic, Results) -->
	html(
		form([action(MainPagePath), method(get)],[
			table([class(form_table), align(center), cellpadding(0)],[
				tr([],[
					td([class(lable)],[
						'Jugglers:'
					]),
					td([class(input)],[
						select([name(persons), size(1)],[
							\html_numbered_options(1, 10, Persons)
						])
					])	
				]),	
				tr([],[
					td([class(lable)],[
						'Objects:'
					]),
					td([class(input)],[
						input([type(text), name(objects), value(Objects)])
					])
				]),
				tr([],[
					td([class(lable)],[
						'Period:'
					]),
					td([class(input)],[
						input([type(text), name(period), value(Period)])
		
					])
				]),
				tr([],[
					td([class(lable)],[
						'Max height:'
					]),
					td([class(input)],[
						select([name(max), size(1)],[
							\html_numbered_options(1, 10, Max)
						])
					])
				]),
				tr([],[
					td([class(lable)],[
						'Passes:'
					]),
					td([class(input)],[
						table([align(left), cellpadding(0)],[
							tr([],[
								td([class(lable)],[
									'min:'
								]),
								td([class(input)],[
									select([name(passesmin), size(1)],[
										\html_numbered_options(0, 9, PassesMin)
									])
								])
							]),
							tr([],[
								td([class(lable)],[
									'max:'
								]),
								td([class(input)],[
									select([name(passesmax), size(1)],[
										\html_numbered_options(0, 9, PassesMax),
										\html_option('-1', PassesMax, &(nbsp))
									])
								])
							])
						])
					])
				]),
				tr([],[
					td([class(lable)],[
						'Contain:'
					]),
					td([class(input)],[
						input([type(text), name(contain), value(Contain)])
					])
				]),
				tr([],[
					td([class(lable)],[
						'Exclude:'
					]),
					td([class(input)],[
						input([type(text), name(exclude), value(Exclude)])
					])
				]),
				tr([],[
					td([class(lable)],[
						'Club does:'
					]),
					td([class(input)],[
						input([type(text), name(clubdoes), value(ClubDoes)])
					])
				]),
				tr([],[
					td([class(lable)],[
						'React:'
					]),
					td([class(input)],[
						input([type(text), name(react), value(React)])
					])
				]),
				tr([],[
					td([class(lable)],[
						'Contain magic:'
					]),
					td([class(input)],[
						\html_checkbox('1', magic, Magic)
					])
				]),
				tr([],[
					td([class(lable)],[
						'Max results:'
					]),
					td([class(input)],[
						input([type(text), name(results), value(Results)])
					])
				]),
				tr([],[
					td([class(lable)],[
					]),
					td([class(input)],[
						input([type(submit), value('Generate')])
					])
				])
			])
		])
	).	

		