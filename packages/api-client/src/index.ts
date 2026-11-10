import {
  Booking,
  Quotation,
  TransferInput,
  ApiResponse,
  parseBooking,
  parseQuotation,
  documentId,
} from "../../types/src";
/** Local v1 client. Legacy numeric/snake_case request contracts are not wire APIs. */
export class PngTransferApiClient {
  private authToken: string | null = null;
  private baseUrl: string;
  constructor(baseUrl = "http://127.0.0.1:8080") {
    const url = new URL(baseUrl);
    if (
      url.protocol !== "http:" ||
      !["127.0.0.1", "localhost"].includes(url.hostname) ||
      url.username ||
      url.password ||
      url.search ||
      url.hash ||
      url.pathname !== "/"
    )
      throw new Error("Local API origin required");
    this.baseUrl = url.origin;
  }
  setAuthToken(token: string | null) {
    this.authToken = token;
  }
  private async request<T>(endpoint: string, body?: unknown): Promise<T> {
    const response = await fetch(this.baseUrl + endpoint, {
      method: body === undefined ? "GET" : "POST",
      redirect: "error",
      signal: AbortSignal.timeout(10000),
      headers: {
        "Content-Type": "application/json",
        ...(this.authToken
          ? { Authorization: "Bearer " + this.authToken }
          : {}),
      },
      ...(body === undefined ? {} : { body: JSON.stringify(body) }),
    });
    const data = (await response.json()) as ApiResponse<T>;
    if (data.schemaVersion !== "1" || !response.ok || !data.success)
      throw new Error(
        !data.success ? data.error?.message : "API contract/request error",
      );
    return data.data;
  }
  async calculateQuote(input: TransferInput): Promise<Quotation> {
    return parseQuotation(
      await this.request("/api/v1/quotes", { schemaVersion: "1", input }),
    );
  }
  async getBooking(id: string): Promise<Booking> {
    return parseBooking(
      await this.request(
        "/api/v1/bookings/" + encodeURIComponent(documentId(id)),
      ),
    );
  }
}
