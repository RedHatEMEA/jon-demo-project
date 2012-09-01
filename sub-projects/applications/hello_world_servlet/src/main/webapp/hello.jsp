<%@page contentType="text/html" import="java.util.*" %>

<%
	int MIN_INTERVAL = 60;

	//Create random number for redirect time
	int randomRedirect = (int) ((Math.random() * 10) * 100 + 500);

	//Read in params
	String startDateParam = request.getParameter("startDate");
	String requestCountParam = request.getParameter("requestCount");
	
	//Initialise all variables to zero
	Long startDate = 0L;
	Integer requestCount = 0;
	Long timePeriod = 0L;
	
	//Check if start date param exists and set to long
	if (startDateParam != null && !startDateParam.isEmpty() && startDateParam.matches("[0-9]*")) {
		startDate = Long.parseLong(startDateParam);
	}
	
	//Check if request count param exists and set to int
	if (requestCountParam != null && !requestCountParam.isEmpty() && requestCountParam.matches("[0-9]*")) {
		requestCount = Integer.parseInt(requestCountParam);
		requestCount++;
	} else {
		requestCount = 0;
	}
	
	//Get current time
	Date currentTime = new Date();
	
	if (startDate == 0L) {
		//If just starting, set start date to 0 and timePeriod to 1
		startDate = currentTime.getTime();
		timePeriod = 1000L;
	} else {
		timePeriod = currentTime.getTime() - startDate;
	}
	
	String timePeriodUnit = "seconds";
	Integer timePeriodInMins = 0;
	
	//Set time period to be seconds (div by 1000 from milli seconds)
	Integer timePeriodInSecs = timePeriod.intValue() / 1000;
	
	//When seconds time period over 60 seconds, set minute variables
	if (timePeriodInSecs > MIN_INTERVAL) {
		Double t = (double)timePeriodInSecs / MIN_INTERVAL;
		timePeriodInMins = t.intValue();
		timePeriodInSecs = timePeriodInSecs % MIN_INTERVAL; 
		timePeriodUnit = "minutes";
	}
	
	//Set second time period text to include appropriate zeroes...
	String timePeriodInSecsText = "00";
	if (timePeriodInSecs < 10) {
		timePeriodInSecsText = "0" + timePeriodInSecs;
	} else {
		timePeriodInSecsText = timePeriodInSecs.toString();
	}
	
	//Set minute time period text to include appropriate zeroes...
	String timePeriodInMinsText = "00";
	if (timePeriodInMins != 0L) {
		Integer t = timePeriodInMins.intValue();		
		if (timePeriodInMins < 10L) {
			timePeriodInMinsText = "0" + timePeriodInMins.intValue();
		} else {
			timePeriodInMinsText = t.toString();
		}
	}
	
	//Calculate average request per minutes depending on secs/mins passed
	Integer averageRequestPerMinute = 0;
	if (timePeriodInMins < 1L) {
		Double t = ((double)requestCount / (timePeriodInSecs == 0 ? 1 : timePeriodInSecs)) * MIN_INTERVAL;
		averageRequestPerMinute = t.intValue();
	} else if (timePeriodInMins == 1L) {
		Double t = ((double)requestCount / (timePeriodInSecs + MIN_INTERVAL)) * MIN_INTERVAL;
		averageRequestPerMinute = t.intValue();
	}
		else {
		averageRequestPerMinute = (requestCount / timePeriodInMins.intValue());
	}
%>

<html>
	<head>
		<script language="JavaScript">
		<!--Script courtesy of http://www.web-source.net - Your Guide to Professional Web Site Design and Development
		var time = null
		function move() {
		window.location = 'hello.jsp?startDate=<%=startDate%>&requestCount=<%=requestCount%>'
		}
		//-->
		</script>
		<title>Hello World - Random Load Generator</title>
	</head>
	<body bgcolor="white" onload="timer=setTimeout('move()',<%=randomRedirect%>)">
	
		<h1>Hello World</h1>
		<p>It's great of you to come along on <%=currentTime %></p>
		<p>This page will be "updated" in <%=randomRedirect%> seconds</p>
		<br />
		<ul>
			<li>debug: timePeriodInSecs == <%=timePeriodInSecs %></li>
			<li>debug: timePeriodInMins == <%=timePeriodInMins %></li>
			<li>Time Period: <%=timePeriodInMinsText%>:<%=timePeriodInSecsText %> <%=timePeriodUnit %></li>
			<li>Request Count: <%=requestCount.intValue() %></li>
			<li>Average Requests per Minute: <%=averageRequestPerMinute %></li>
		</ul>
	</body>
</html>