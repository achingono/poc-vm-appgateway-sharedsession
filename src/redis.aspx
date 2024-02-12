<%@ Page Language="c#" MasterPageFile="~/master/shell.master" AutoEventWireup="false" Inherits="System.Web.UI.Page" %>
<script runat="server">
	public void Page_Load(object sender, EventArgs args) {
		if (IsPostBack) {
			Session[Request.Form["key"]] = Request.Form["value"];
			throw new Exception("");
		}
	}
	protected void SaveSession_OnClick(object sender, EventArgs args) {
		Session[Request.Form["key"]] = Request.Form["value"];
	}
</script>
<asp:Content ID="PageContent" ContentPlaceHolderID="Container" Runat="Server">

	<h1 class="title">Session Test</h1>
	<div class="section">
		<form runat="server" class="form" action="" method="post">
			<h2 class="subtitle">Add Session Item</h2>
			<div class="field is-horizontal">
				<div class="field-label is-normal">
					<label class="label">Key:</label>
				</div>
				<div class="field-body">
					<div class="field">
						<div class="control">
							<input name="key" class="input" type="text" placeholder="Session key">
						</div>
					</div>
				</div>
			</div>
			<div class="field is-horizontal">
				<div class="field-label is-normal">
					<label class="label">Value:</label>
				</div>
				<div class="field-body">
					<div class="field">
						<div class="control">
							<input name="value" class="input" type="text" placeholder="Session value">
						</div>
					</div>
				</div>
			</div>

			<div class="field is-horizontal">
				<div class="field-label">
					<!-- Left empty for spacing -->
				</div>
				<div class="field-body">
					<div class="field">
						<div class="control">
							<asp:button runat="server" type="submit" class="button is-primary" Text="Save Session" OnClick="SaveSession_OnClick">
							</asp:button>
						</div>
					</div>
				</div>
			</div>
		</form>
	</div>

	<div class="section">
		<h2 class="subtitle">Session Items</h2>
		<table class="table is-fullwidth">
			<thead>
				<tr>
					<th>Key</th>
					<th>Value</th>
				</tr>
			</thead>
			<tbody>
				<%
                foreach (string key in Session.Contents)
                {
                    Response.Write("<tr><td>" + key + "</td><td>" + Session[key].ToString() + "</td></tr>");
                }
                %>
			</tbody>
		</table>
	</div>

</asp:Content>